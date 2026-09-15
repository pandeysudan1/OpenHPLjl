using Printf
using DelimitedFiles

# Torpa-like screening model. Parameters are illustrative and must be
# replaced by plant data before engineering use.

struct PlantParams
    Prated::Float64
    Tw::Float64
    Tg::Float64
    Tr::Float64
    Rt::Float64
    D::Float64
    Hm::Float64
    qmin::Float64
    qmax::Float64
    hmin::Float64
    hmax::Float64
    gate_rate_max::Float64
end

const P = PlantParams(100.0, 1.8, 0.35, 5.0, 0.35, 1.0, 4.0,
                      0.20, 1.20, 0.82, 1.12, 0.08)

const dt = 0.02
const t_end = 40.0
const t_step = 2.0

# FCR-D Up screening disturbance: 50.0 -> 49.5 Hz.
freq(t) = t < t_step ? 50.0 : 49.5

function rhs(x, t, p0, cfcr, droop, P::PlantParams)
    q, w, yg, xr = x
    df = freq(t) - 50.0
    cmd = clamp((-df / 0.5) * (cfcr / P.Prated), 0.0, cfcr / P.Prated)
    droop_gain = 0.05 / droop
    gov = p0 + droop_gain * cmd + P.Rt * (xr - (w - 1.0))
    dyg_raw = (gov - yg) / P.Tg
    dyg = clamp(dyg_raw, -P.gate_rate_max, P.gate_rate_max)
    dxr = ((w - 1.0) - xr) / P.Tr

    # Simple nonlinear waterway: guide-vane demand drives flow, quadratic
    # friction reduces head. This is only the screening layer; it is intended
    # to be replaced by connected OpenHPL hydraulic components.
    head = 1.0 - 0.10 * q * abs(q)
    dq = (yg * sqrt(max(head, 0.05)) - q) / P.Tw
    pm = q * head
    pe = p0
    dw = (pm - pe - P.D * (w - 1.0)) / (2P.Hm)
    return (dq, dw, dyg, dxr), head, pm
end

function rk4_step(x, t, h, p0, cfcr, droop, P)
    k1, _, _ = rhs(x, t, p0, cfcr, droop, P)
    x2 = ntuple(i -> x[i] + 0.5h*k1[i], 4)
    k2, _, _ = rhs(x2, t + 0.5h, p0, cfcr, droop, P)
    x3 = ntuple(i -> x[i] + 0.5h*k2[i], 4)
    k3, _, _ = rhs(x3, t + 0.5h, p0, cfcr, droop, P)
    x4 = ntuple(i -> x[i] + h*k3[i], 4)
    k4, _, _ = rhs(x4, t + h, p0, cfcr, droop, P)
    return ntuple(i -> x[i] + h*(k1[i] + 2k2[i] + 2k3[i] + k4[i])/6, 4)
end

function simulate(p0, cfcr, droop)
    n = Int(round(t_end/dt)) + 1
    t = collect(range(0.0, t_end, length=n))
    x = (p0, 1.0, p0, 0.0)
    q = zeros(n); w = zeros(n); yg = zeros(n); xr = zeros(n)
    h = zeros(n); pm = zeros(n); f = zeros(n)
    for k in eachindex(t)
        q[k], w[k], yg[k], xr[k] = x
        _, h[k], pm[k] = rhs(x, t[k], p0, cfcr, droop, P)
        f[k] = freq(t[k])
        if k < n
            x = rk4_step(x, t[k], dt, p0, cfcr, droop, P)
        end
    end
    return (; t, q, w, yg, xr, h, pm, f)
end

function at_time(t, y, τ)
    i = argmin(abs.(t .- τ))
    return y[i]
end

function evaluate(p0, cfcr, droop)
    s = simulate(p0, cfcr, droop)
    pbase = p0 * P.Prated
    response = (s.pm .* P.Prated) .- pbase
    r75 = at_time(s.t, response, t_step + 7.5)
    r30 = at_time(s.t, response, t_step + 30.0)
    target75 = 0.86cfcr
    target30 = cfcr
    dyn_pass = r75 >= target75 && r30 >= 0.98target30
    hyd_pass = minimum(s.q) >= P.qmin && maximum(s.q) <= P.qmax &&
               minimum(s.h) >= P.hmin && maximum(s.h) <= P.hmax &&
               minimum(s.yg) >= -1e-6 && maximum(s.yg) <= 1.0 + 1e-6
    # Screening stability proxy: bounded speed excursion and decaying final error.
    speed_dev = maximum(abs.((s.w .- 1.0) .* 50.0))
    stable = speed_dev < 1.0 && abs(s.w[end] - s.w[end-100]) < 2e-4
    pass = dyn_pass && hyd_pass && stable
    return (; p0, cfcr, droop, r75, r30, dyn_pass, hyd_pass, stable, pass, speed_dev, s)
end

mkpath(joinpath(@__DIR__, "results"))

ops = [0.40, 0.60, 0.80]
capacities = [5.0, 10.0, 15.0, 20.0]
droops = [0.04, 0.05, 0.06]
rows = Any[]

for p0 in ops, c in capacities, r in droops
    e = evaluate(p0, c, r)
    push!(rows, [p0, c, 100r, e.r75, e.r30, e.dyn_pass, e.hyd_pass, e.stable, e.pass, e.speed_dev])
end

open(joinpath(@__DIR__, "results", "screening_summary.csv"), "w") do io
    println(io, "operating_point_pu,fcr_mw,droop_pct,response_7p5s_mw,response_30s_mw,dynamic_pass,hydraulic_pass,stable,overall_pass,max_speed_dev_hz")
    for r in rows
        println(io, join(r, ','))
    end
end

# Best passing capacity by operating point (over all droops).
open(joinpath(@__DIR__, "results", "capacity_envelope.csv"), "w") do io
    println(io, "operating_point_pu,max_qualified_fcr_mw")
    for p0 in ops
        passed = [Float64(r[2]) for r in rows if r[1] == p0 && r[9] == true]
        cmax = isempty(passed) ? 0.0 : maximum(passed)
        println(io, "$(p0),$(cmax)")
        @printf("P0=%3.0f%%  max screened FCR = %5.1f MW\n", 100p0, cmax)
    end
end

# Export one representative trajectory for plotting/review.
rep = evaluate(0.60, 15.0, 0.05).s
open(joinpath(@__DIR__, "results", "representative_case.csv"), "w") do io
    println(io, "t_s,freq_hz,flow_pu,head_pu,gate_pu,speed_pu,pmech_pu")
    for i in eachindex(rep.t)
        println(io, join((rep.t[i], rep.f[i], rep.q[i], rep.h[i], rep.yg[i], rep.w[i], rep.pm[i]), ','))
    end
end

println("Wrote 36-case screening summary and representative trajectory to examples/torpa_fcr_capacity_screening/results/")