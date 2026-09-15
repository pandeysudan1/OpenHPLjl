using Printf

# Torpa-like FCR-D Up capacity screening model.
# All plant parameters are illustrative. Replace them with plant data before
# any engineering or commercial use.

struct PlantParams
    Prated::Float64
    Tw::Float64
    Tg::Float64
    Tr::Float64
    Rt::Float64
    qmin::Float64
    qmax::Float64
    hmin::Float64
    hmax::Float64
    gate_rate_max::Float64
    kfric::Float64
end

const P = PlantParams(
    100.0,  # MW
    1.8,    # water starting time, s
    0.35,   # gate servo time constant, s
    5.0,    # transient-droop recovery time, s
    0.35,   # transient-droop strength
    0.20,   # min flow, pu
    1.20,   # max flow, pu
    0.82,   # min head, pu
    1.12,   # max head, pu
    0.08,   # max gate velocity, pu/s
    0.10    # quadratic hydraulic loss coefficient
)

const dt = 0.02
const t_end = 40.0
const t_step = 2.0

# FCR-D Up test signal: 50.0 -> 49.5 Hz.
freq(t) = t < t_step ? 50.0 : 49.5

"""
Reduced screening dynamics.

States:
    q   water flow [pu]
    yg  guide-vane opening [pu]
    xr  recovered FCR command state [pu power]

The grid frequency is imposed by the prequalification test. We therefore do
not integrate a separate swing equation here; doing both would over-specify
frequency. Generator/grid dynamics are added later in the full OpenHPL model.

The hydraulic head is written relative to the selected operating point, so
q = yg = p0 and head = 1 form an exact pre-disturbance equilibrium.
"""
function rhs(x, t, p0, cfcr, droop, P::PlantParams)
    q, yg, xr = x

    df_pu = (freq(t) - 50.0) / 50.0
    reserve_cap_pu = cfcr / P.Prated

    # Primary droop request, capped by the contracted FCR capacity.
    fcr_request = clamp(-df_pu / droop, 0.0, reserve_cap_pu)

    # Simple transient-droop recovery: suppress the first gate movement and
    # progressively recover toward the steady droop request.
    dxr = (fcr_request - xr) / P.Tr
    governor_target = p0 + fcr_request - P.Rt * (fcr_request - xr)

    dyg_raw = (governor_target - yg) / P.Tg
    dyg = clamp(dyg_raw, -P.gate_rate_max, P.gate_rate_max)

    # Nonlinear screening waterway. The reference-loss term makes the chosen
    # pre-disturbance point an exact equilibrium rather than an artificial
    # transient before the frequency event.
    head = 1.0 - P.kfric * (q * abs(q) - p0 * abs(p0))
    head_eff = max(head, 0.05)
    dq = (yg * sqrt(head_eff) - q) / P.Tw

    pm = q * head
    return (dq, dyg, dxr), head, pm, fcr_request
end

function rk4_step(x, t, h, p0, cfcr, droop, P)
    k1, _, _, _ = rhs(x, t, p0, cfcr, droop, P)
    x2 = ntuple(i -> x[i] + 0.5h * k1[i], 3)
    k2, _, _, _ = rhs(x2, t + 0.5h, p0, cfcr, droop, P)
    x3 = ntuple(i -> x[i] + 0.5h * k2[i], 3)
    k3, _, _, _ = rhs(x3, t + 0.5h, p0, cfcr, droop, P)
    x4 = ntuple(i -> x[i] + h * k3[i], 3)
    k4, _, _, _ = rhs(x4, t + h, p0, cfcr, droop, P)
    return ntuple(i -> x[i] + h * (k1[i] + 2k2[i] + 2k3[i] + k4[i]) / 6, 3)
end

function simulate(p0, cfcr, droop)
    n = Int(round(t_end / dt)) + 1
    t = collect(range(0.0, t_end, length=n))

    # Exact equilibrium before the test event.
    x = (p0, p0, 0.0)

    q = zeros(n)
    yg = zeros(n)
    xr = zeros(n)
    h = zeros(n)
    pm = zeros(n)
    f = zeros(n)
    request = zeros(n)

    for k in eachindex(t)
        q[k], yg[k], xr[k] = x
        _, h[k], pm[k], request[k] = rhs(x, t[k], p0, cfcr, droop, P)
        f[k] = freq(t[k])
        if k < n
            x = rk4_step(x, t[k], dt, p0, cfcr, droop, P)
        end
    end

    return (; t, q, yg, xr, h, pm, f, request)
end

function at_time(t, y, τ)
    i = argmin(abs.(t .- τ))
    return y[i]
end

function evaluate(p0, cfcr, droop)
    s = simulate(p0, cfcr, droop)
    pbase = p0 * P.Prated
    response = s.pm .* P.Prated .- pbase

    r75 = at_time(s.t, response, t_step + 7.5)
    r30 = at_time(s.t, response, t_step + 30.0)

    target75 = 0.86 * cfcr
    target30 = cfcr
    dynamic_pass = r75 >= target75 && r30 >= 0.98 * target30

    hydraulic_pass = minimum(s.q) >= P.qmin && maximum(s.q) <= P.qmax &&
                     minimum(s.h) >= P.hmin && maximum(s.h) <= P.hmax &&
                     minimum(s.yg) >= -1e-9 && maximum(s.yg) <= 1.0 + 1e-9

    # Reduced-model settling screen. The full study will replace this with
    # linearized eigenvalue / frequency-domain stability checks.
    settled = abs(s.pm[end] - s.pm[end-100]) < 2e-4

    overall_pass = dynamic_pass && hydraulic_pass && settled

    limiting_reason = if !dynamic_pass
        "dynamic_response"
    elseif !hydraulic_pass
        "hydraulic_or_gate_limit"
    elseif !settled
        "not_settled"
    else
        "pass"
    end

    return (; p0, cfcr, droop, r75, r30, dynamic_pass, hydraulic_pass,
            settled, overall_pass, limiting_reason, s)
end

results_dir = joinpath(@__DIR__, "results")
mkpath(results_dir)

ops = [0.40, 0.60, 0.80]
capacities = [5.0, 10.0, 15.0, 20.0]
droops = [0.04, 0.05, 0.06]
rows = Any[]

for p0 in ops, c in capacities, r in droops
    e = evaluate(p0, c, r)
    push!(rows, [p0, c, 100r, e.r75, e.r30, e.dynamic_pass,
                 e.hydraulic_pass, e.settled, e.overall_pass,
                 e.limiting_reason])
end

open(joinpath(results_dir, "screening_summary.csv"), "w") do io
    println(io, "operating_point_pu,fcr_mw,droop_pct,response_7p5s_mw,response_30s_mw,dynamic_pass,hydraulic_pass,settled,overall_pass,limiting_reason")
    for r in rows
        println(io, join(r, ','))
    end
end

open(joinpath(results_dir, "capacity_envelope.csv"), "w") do io
    println(io, "operating_point_pu,max_qualified_fcr_mw")
    for p0 in ops
        passed = [Float64(r[2]) for r in rows if r[1] == p0 && r[9] == true]
        cmax = isempty(passed) ? 0.0 : maximum(passed)
        println(io, "$(p0),$(cmax)")
        @printf("P0=%3.0f%%  max screened FCR = %5.1f MW\n", 100p0, cmax)
    end
end

rep_eval = evaluate(0.60, 15.0, 0.05)
rep = rep_eval.s
open(joinpath(results_dir, "representative_case.csv"), "w") do io
    println(io, "t_s,freq_hz,fcr_request_pu,flow_pu,head_pu,gate_pu,recovery_state_pu,pmech_pu")
    for i in eachindex(rep.t)
        println(io, join((rep.t[i], rep.f[i], rep.request[i], rep.q[i], rep.h[i],
                         rep.yg[i], rep.xr[i], rep.pm[i]), ','))
    end
end

println("Wrote 36-case screening summary, capacity envelope, and representative trajectory.")
println("Representative case limiting reason: $(rep_eval.limiting_reason)")
