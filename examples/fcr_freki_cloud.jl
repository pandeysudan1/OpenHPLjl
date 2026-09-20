using OpenHPLjl
using ModelingToolkit
using OrdinaryDiffEq
using Printf

outdir = joinpath(@__DIR__, "..", "artifacts", "fcr_freki")
mkpath(outdir)

function write_csv(path, headers, cols)
    open(path, "w") do io
        println(io, join(headers, ","))
        n = length(cols[1])
        for i in 1:n
            println(io, join((cols[j][i] for j in eachindex(cols)), ","))
        end
    end
end

function line_svg(path, title, x, series; xlabel="Time [s]", ylabel="")
    W, H = 900, 430
    ml, mr, mt, mb = 72, 28, 48, 58
    pw, ph = W-ml-mr, H-mt-mb
    xmin, xmax = extrema(x)
    ysall = reduce(vcat, [s[2] for s in series])
    ymin, ymax = extrema(ysall)
    if ymax == ymin
        ymax += 1
        ymin -= 1
    end
    pad = 0.08 * (ymax-ymin)
    ymin -= pad
    ymax += pad
    sx(v) = ml + (v-xmin)/(xmax-xmin)*pw
    sy(v) = mt + ph - (v-ymin)/(ymax-ymin)*ph
    colors = ["#1f77b4", "#d62728", "#2ca02c", "#9467bd"]

    open(path, "w") do io
        println(io, "<svg xmlns=\"http://www.w3.org/2000/svg\" width=\"$W\" height=\"$H\" viewBox=\"0 0 $W $H\">")
        println(io, "<style>text{font-family:Arial,sans-serif;fill:#222}.grid{stroke:#ddd}.axis{stroke:#333;stroke-width:1.3}.lab{font-size:13px}.title{font-size:18px;font-weight:700}.legend{font-size:12px}</style>")
        println(io, "<rect width=\"100%\" height=\"100%\" fill=\"white\"/>")
        println(io, "<text x=\"$(W/2)\" y=\"26\" text-anchor=\"middle\" class=\"title\">$title</text>")
        for k in 0:5
            xv = xmin + (xmax-xmin)*k/5
            yv = ymin + (ymax-ymin)*k/5
            println(io, "<line x1=\"$(sx(xv))\" y1=\"$mt\" x2=\"$(sx(xv))\" y2=\"$(mt+ph)\" class=\"grid\"/>")
            println(io, "<text x=\"$(sx(xv))\" y=\"$(mt+ph+22)\" text-anchor=\"middle\" class=\"lab\">$(@sprintf("%.2f", xv))</text>")
            println(io, "<line x1=\"$ml\" y1=\"$(sy(yv))\" x2=\"$(ml+pw)\" y2=\"$(sy(yv))\" class=\"grid\"/>")
            println(io, "<text x=\"$(ml-10)\" y=\"$(sy(yv)+4)\" text-anchor=\"end\" class=\"lab\">$(@sprintf("%.3g", yv))</text>")
        end
        println(io, "<line x1=\"$ml\" y1=\"$(mt+ph)\" x2=\"$(ml+pw)\" y2=\"$(mt+ph)\" class=\"axis\"/>")
        println(io, "<line x1=\"$ml\" y1=\"$mt\" x2=\"$ml\" y2=\"$(mt+ph)\" class=\"axis\"/>")
        println(io, "<text x=\"$(ml+pw/2)\" y=\"$(H-12)\" text-anchor=\"middle\" class=\"lab\">$xlabel</text>")
        println(io, "<text x=\"18\" y=\"$(mt+ph/2)\" transform=\"rotate(-90 18 $(mt+ph/2))\" text-anchor=\"middle\" class=\"lab\">$ylabel</text>")
        for (j, (name, ys)) in enumerate(series)
            pts = join(["$(@sprintf("%.1f", sx(x[i]))),$(@sprintf("%.1f", sy(ys[i])))" for i in eachindex(x)], " ")
            col = colors[mod1(j, length(colors))]
            println(io, "<polyline points=\"$pts\" fill=\"none\" stroke=\"$col\" stroke-width=\"2.4\"/>")
            ly = mt + 18 + (j-1)*19
            println(io, "<line x1=\"$(ml+10)\" y1=\"$ly\" x2=\"$(ml+34)\" y2=\"$ly\" stroke=\"$col\" stroke-width=\"3\"/>")
            println(io, "<text x=\"$(ml+42)\" y=\"$(ly+4)\" class=\"legend\">$name</text>")
        end
        println(io, "</svg>")
    end
end

println("=== FCR-D up ramp test ===")
@named ramp_plant = FCRTestSMIB(
    product = :FCRDUp,
    test = :ramp,
    f0 = 49.9,
    ramp_f_start = 49.9,
    ramp_f_end = 49.0,
    ramp_t_start = 5.0,
    ramp_time = 3.75,
    gate_range = 0.12,
    Tg = 0.20,
)
ramp_sys = mtkcompile(ramp_plant)
ramp_prob = ODEProblem(ramp_sys, [], (0.0, 30.0))
ramp_sol = solve(ramp_prob, Rodas5P(); abstol=1e-8, reltol=1e-8)

tr = collect(range(0.0, 30.0, length=3001))
fr = collect(ramp_sol(tr, idxs=ramp_sys.grid.f))
pr = collect(ramp_sol(tr, idxs=ramp_sys.generator.Pe)) ./ 1e6
yr = collect(ramp_sol(tr, idxs=ramp_sys.controller.y))
qr = collect(ramp_sol(tr, idxs=ramp_sys.turbine.Q))

t0 = 5.0
p0 = ramp_sol(t0, idxs=ramp_sys.generator.Pe) / 1e6
pss = sum(pr[end-99:end]) / 100 - p0
m = fcrd_metrics(tr, pr; t0=t0, p_baseline=p0, p_ss_theoretical=pss)

@printf("Full model response: %.4f MW\n", pss)
@printf("P7.5/Pss: %.4f\n", m.P75_ratio)
@printf("E7.5/Pss: %.4f s\n", m.E75_ratio_s)
@printf("Initiation delay: %.4f s\n", m.initiation_delay_s)

write_csv(joinpath(outdir, "fcrd_ramp.csv"),
          ["t_s","f_Hz","Pe_MW","gate_pu","Q_m3s"],
          [tr,fr,pr,yr,qr])
line_svg(joinpath(outdir, "fcrd_power.svg"), "FCR-D up: frequency and normalized power", tr,
         [("frequency deviation ×10 [Hz]", (fr .- 49.9).*10),
          ("ΔPe / |ΔPss|", (pr .- p0)./abs(pss))],
         ylabel="Normalized / scaled")
line_svg(joinpath(outdir, "fcrd_hydraulic.svg"), "FCR-D up: gate and turbine flow", tr,
         [("gate [pu]", yr), ("flow / 10 [pu]", qr./10)],
         ylabel="Per unit")

println("=== FCR-N sine sweep ===")
periods = [10.0,15.0,25.0,40.0,50.0,60.0,70.0,90.0,150.0,300.0]
gains = Float64[]
phases = Float64[]
linearities = Float64[]

for T in periods
    @named sine_plant = FCRTestSMIB(
        product = :FCRN,
        test = :sine,
        f0 = 50.0,
        sine_center = 50.0,
        sine_amplitude = 0.1,
        sine_period = T,
        sine_t_start = 5.0,
        gate_range = 0.04,
        Tg = 0.20,
    )
    sys = mtkcompile(sine_plant)
    tend = 5.0 + 4*T
    prob = ODEProblem(sys, [], (0.0, tend))
    sol = solve(prob, Rodas5P(); abstol=1e-7, reltol=1e-7)

    # Fit last three stationary periods.
    ta = tend - 3*T
    ts = collect(range(ta, tend, length=1201))
    fs = collect(sol(ts, idxs=sys.grid.f))
    ps = collect(sol(ts, idxs=sys.generator.Pe)) ./ 1e6

    pbase = sum(ps) / length(ps)
    # Use measured full response scale from the actual sine amplitude/output relation.
    # For normalized screening, df_full is 0.1 Hz and dp_full is 1 MW.
    r = normalized_fcr_sine_response(ts, fs, ps; period=T, df_full=0.1, dp_full=1.0)
    push!(gains, r.gain)
    push!(phases, r.phase_deg)
    push!(linearities, r.linearity_index)
    @printf("T=%6.1f s gain=%8.4f phase=%8.2f deg linearity=%7.4f\n",
            T, r.gain, r.phase_deg, r.linearity_index)
end

write_csv(joinpath(outdir, "fcrn_sine_sweep.csv"),
          ["period_s","gain_norm","phase_deg","linearity_index"],
          [periods,gains,phases,linearities])
line_svg(joinpath(outdir, "fcrn_gain.svg"), "FCR-N sine sweep: normalized gain", periods,
         [("gain", gains)], xlabel="Period [s]", ylabel="Normalized gain")
line_svg(joinpath(outdir, "fcrn_phase.svg"), "FCR-N sine sweep: phase", periods,
         [("phase [deg]", phases)], xlabel="Period [s]", ylabel="Phase [deg]")
line_svg(joinpath(outdir, "fcrn_linearity.svg"), "FCR-N sine sweep: linearity index", periods,
         [("linearity", linearities)], xlabel="Period [s]", ylabel="RMS residual / σfit")

summary_path = joinpath(outdir, "RESULTS.md")
open(summary_path, "w") do io
    println(io, "# Cloud-run FCR + FREKI screening results")
    println(io)
    println(io, "Generated by GitHub Actions with Julia ", VERSION, ".")
    println(io)
    println(io, "## FCR-D up ramp")
    println(io)
    println(io, "| Metric | Value | Screening threshold |")
    println(io, "|---|---:|---:|")
    println(io, "| Full model response | $(@sprintf("%.4f", pss)) MW | model-derived |")
    println(io, "| P7.5/Pss | $(@sprintf("%.4f", m.P75_ratio)) | >= 0.86 |")
    println(io, "| E7.5/Pss | $(@sprintf("%.4f", m.E75_ratio_s)) s | >= 3.2 s |")
    println(io, "| initiation delay | $(@sprintf("%.4f", m.initiation_delay_s)) s | <= 2.5 s |")
    println(io, "| max ratio <=7.5 s | $(@sprintf("%.4f", m.max_ratio_t_le_7_5)) | <= 1.50 |")
    println(io, "| max ratio >7.5 s | $(@sprintf("%.4f", m.max_ratio_t_gt_7_5)) | <= 1.20 |")
    println(io)
    println(io, "![FCR-D power](fcrd_power.svg)")
    println(io)
    println(io, "![FCR-D hydraulic](fcrd_hydraulic.svg)")
    println(io)
    println(io, "## FCR-N sine sweep")
    println(io)
    println(io, "| Period [s] | Gain | Phase [deg] | Linearity |")
    println(io, "|---:|---:|---:|---:|")
    for i in eachindex(periods)
        println(io, "| $(@sprintf("%.0f", periods[i])) | $(@sprintf("%.4f", gains[i])) | $(@sprintf("%.2f", phases[i])) | $(@sprintf("%.4f", linearities[i])) |")
    end
    println(io)
    println(io, "![Gain](fcrn_gain.svg)")
    println(io)
    println(io, "![Phase](fcrn_phase.svg)")
    println(io)
    println(io, "![Linearity](fcrn_linearity.svg)")
    println(io)
    println(io, "> Screening only. Formal prequalification must use the current Statnett/Nordic procedure and provider-specific theoretical steady-state response.")
end

println("Artifacts written to ", abspath(outdir))
