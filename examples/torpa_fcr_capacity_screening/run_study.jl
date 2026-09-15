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
    1.0,    # water starting time, s
    0.20,   # gate servo time constant, s
    2.5,    # transient-droop recovery time, s
    0.20,   # transient-droop strength
    0.20,   # min flow, pu
    1.20,   # max flow, pu
    0.82,   # min head, pu
    1.12,   # max head, pu
    0.15,   # max gate velocity, pu/s
    0.10    # quadratic hydraulic loss coefficient
)

const dt = 0.02
const t_end = 40.0
const t_step = 2.0

# Nordic FCR-D dynamic screening signal: ramp from 49.9 Hz toward 49.0 Hz
# at 0.24 Hz/s. Full contracted FCR-D Up is reached by 49.5 Hz.
function freq(t)
    t < t_step && return 49.9
    return max(49.0, 49.9 - 0.24 * (t - t_step))
end

"""Return steady guide-vane opening required for a desired mechanical power."""
function gate_for_power(p0, pdes, P::PlantParams)
    lo, hi = 0.01, 1.40
    for _ in 1:60
        q = 0.5 * (lo + hi)
        head = 1.0 - P.kfric * (q^2 - p0^2)
        pm = q * head
        if pm < pdes
            lo = q
        else
            hi = q
        end
    end
    q = 0.5 * (lo + hi)
    head = 1.0 - P.kfric * (q^2 - p0^2)
    return q / sqrt(max(head, 0.05))
end

"""
Reduced screening dynamics.

States:
    q   water flow [pu]
    yg  guide-vane opening [pu]
    xr  recovered gate-increment state [pu]

Frequency is imposed by the prequalification test, so a separate swing
frequency state is intentionally not integrated in this reduced model.
"""
function rhs(x, t, p0, cfcr, droop, P::PlantParams)
    q, yg, xr = x
    f = freq(t)

    # Linear FCR-D activation from 49.9 to 49.5 Hz.
    activation = clamp((49.9 - f) / 0.4, 0.0, 1.0)

    # A 0.5-Hz deviation corresponds to 0.01 pu frequency deviation.
    # The droop setting therefore limits the physically available steady
    # primary response. Contracted FCR is capped by that capability.
    droop_cap_mw = P.Prated * (0.01 / droop)
    request_mw = min(cfcr, droop_cap_mw) * activation
    request_pu = request_mw / P.Prated

    # Convert requested mechanical power to a steady gate target through the
    # nonlinear hydraulic map instead of assuming gate == power.
    gate_target = gate_for_power(p0, p0 + request_pu, P)
    dgate_target = gate_target - p0

    # Simple transient-droop recovery.
    dxr = (dgate_target - xr) / P.Tr
    governor_target = p0 + dgate_target - P.Rt * (dgate_target - xr)

    dyg_raw = (governor_target - yg) / P.Tg
    dyg = clamp(dyg_raw, -P.gate_rate_max, P.gate_rate_max)

    # Nonlinear reduced waterway, normalized so q = yg = p0 and head = 1
    # are an exact pre-disturbance equilibrium.
    head = 1.0 - P.kfric * (q * abs(q) - p0 * abs(p0))
    dq = (yg * sqrt(max(head, 0.05)) - q) / P.Tw
    pm = q * head

    return (dq, dyg, dxr), head, pm, request_mw
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
    x = (p0, p0, 0.0)

    q = zeros(n); yg = zeros(n); xr = zeros(n)
    h = zeros(n); pm = zeros(n); f = zeros(n); request = zeros(n)

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

at_time(t, y, τ) = y[argmin(abs.(t .- τ))]

function trapz_between(t, y, ta, tb)
    idx = findall(x -> ta <= x <= tb, t)
    e = 0.0
    for k in 1:length(idx)-1
        i, j = idx[k], idx[k+1]
        e += 0.5 * (y[i] + y[j]) * (t[j] - t[i])
    end
    return e
end

function evaluate(p0, cfcr, droop)
    s = simulate(p0, cfcr, droop)
    pbase = p0 * P.Prated
    response = s.pm .* P.Prated .- pbase

    r75 = at_time(s.t, response, t_step + 7.5)
    e75 = trapz_between(s.t, response, t_step, t_step + 7.5)
    rss = response[end]
    rmax = maximum(response)

    # Nordic FCR-D dynamic screens used in this prototype:
    # P(7.5 s) >= 86%, E(0..7.5 s) >= 3.2 s * capacity,
    # steady response within -5/+10%, and <=20% overshoot.
    dynamic_pass = r75 >= 0.86 * cfcr &&
                   e75 >= 3.2 * cfcr &&
                   rss >= 0.95 * cfcr && rss <= 1.10 * cfcr &&
                   rmax <= 1.20 * cfcr

    hydraulic_pass = minimum(s.q) >= P.qmin && maximum(s.q) <= P.qmax &&
                     minimum(s.h) >= P.hmin && maximum(s.h) <= P.hmax &&
                     minimum(s.yg) >= -1e-9 && maximum(s.yg) <= 1.0 + 1e-9

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

    return (; p0, cfcr, droop, r75, e75, rss, rmax, dynamic_pass,
            hydraulic_pass, settled, overall_pass, limiting_reason, s)
end

results_dir = joinpath(@__DIR__, "results")
mkpath(results_dir)

ops = [0.40, 0.60, 0.80]
capacities = [5.0, 10.0, 15.0, 20.0]
droops = [0.04, 0.05, 0.06]
rows = Any[]

for p0 in ops, c in capacities, r in droops
    e = evaluate(p0, c, r)
    push!(rows, [p0, c, 100r, e.r75, e.e75, e.rss, e.rmax,
                 e.dynamic_pass, e.hydraulic_pass, e.settled,
                 e.overall_pass, e.limiting_reason])
end

open(joinpath(results_dir, "screening_summary.csv"), "w") do io
    println(io, "operating_point_pu,fcr_mw,droop_pct,response_7p5s_mw,energy_7p5s_mws,steady_response_mw,max_response_mw,dynamic_pass,hydraulic_pass,settled,overall_pass,limiting_reason")
    for r in rows
        println(io, join(r, ','))
    end
end

open(joinpath(results_dir, "capacity_envelope.csv"), "w") do io
    println(io, "operating_point_pu,max_qualified_fcr_mw")
    for p0 in ops
        passed = [Float64(r[2]) for r in rows if r[1] == p0 && r[11] == true]
        cmax = isempty(passed) ? 0.0 : maximum(passed)
        println(io, "$(p0),$(cmax)")
        @printf("P0=%3.0f%%  max screened FCR = %5.1f MW\n", 100p0, cmax)
    end
end

rep_eval = evaluate(0.60, 15.0, 0.05)
rep = rep_eval.s
open(joinpath(results_dir, "representative_case.csv"), "w") do io
    println(io, "t_s,freq_hz,fcr_request_mw,flow_pu,head_pu,gate_pu,recovery_state_pu,pmech_pu")
    for i in eachindex(rep.t)
        println(io, join((rep.t[i], rep.f[i], rep.request[i], rep.q[i], rep.h[i],
                         rep.yg[i], rep.xr[i], rep.pm[i]), ','))
    end
end

println("Wrote 36-case screening summary, capacity envelope, and representative trajectory.")
println("Representative case limiting reason: $(rep_eval.limiting_reason)")
