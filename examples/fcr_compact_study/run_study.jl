using Printf

const F0, EVENT_TIME, T_END, DT = 50.0, 5.0, 35.0, 0.01
const DP, H, DAMPING, TW, Y_REF = 0.10, 4.0, 1.0, 1.0, 0.80

load_step(t) = t < EVENT_TIME ? 0.0 : DP

function rk4(rhs, x, t, dt, p)
    k1 = rhs(x, t, p)
    k2 = rhs(x .+ 0.5dt .* k1, t + 0.5dt, p)
    k3 = rhs(x .+ 0.5dt .* k2, t + 0.5dt, p)
    k4 = rhs(x .+ dt .* k3, t + dt, p)
    x .+ (dt / 6) .* (k1 .+ 2k2 .+ 2k3 .+ k4)
end

# Δfrequency [pu], Δgate [pu], Δmechanical power [pu]
function standard_rhs(x, t, p)
    w, u, pm = x
    R, Tg = p
    command = clamp(-w / R, -Y_REF, 1 - Y_REF)
    [(pm - load_step(t) - DAMPING*w)/(2H), (command-u)/Tg, (u-pm)/TW]
end

# OpenHPL transient-droop core plus a reduced water-column lag.
# Δfrequency, transient state, pilot state, guide vane, Δmechanical power
function transient_rhs(x, t, p)
    w, xr, xp, Y, pm = x
    droop, Tr = p
    delta, Tp, Tg = 0.04, 0.04, 0.20
    e = -w - (delta*Y - xr) + droop*(Y_REF-Y)
    rate = clamp(xp/Tg, -0.20, 0.05)
    [(pm-load_step(t)-DAMPING*w)/(2H), (delta*Y-xr)/Tr,
     (e-xp)/Tp, rate, ((Y-Y_REF)-pm)/TW]
end

function simulate(kind; droop=0.05, Tg=0.40, Tr=1.75)
    times = collect(0.0:DT:T_END)
    if kind == :standard
        x, rhs, pars = [0.0,0.0,0.0], standard_rhs, (droop,Tg)
    else
        x, rhs, pars = [0.0,0.04Y_REF,0.0,Y_REF,0.0], transient_rhs, (droop,Tr)
    end
    f=similar(times); gate=similar(times); power=similar(times)
    for (i,t) in enumerate(times)
        f[i] = F0*(1+x[1]); gate[i] = kind == :standard ? Y_REF+x[2] : x[4]
        power[i] = x[end]
        i < length(times) && (x = rk4(rhs,x,t,DT,pars))
    end
    (;times,f,gate,power)
end

function metrics(name, run)
    event_i = round(Int,EVENT_TIME/DT)+1
    post = event_i:length(run.times)
    nadir, j = findmin(run.f[post]); ni=first(post)+j-1
    at(s) = round(Int,(EVENT_TIME+s)/DT)+1
    (;name,nadir,nadir_time=run.times[ni]-EVENT_TIME,
      p5=run.power[at(5)],p15=run.power[at(15)],p30=run.power[at(30)],
      f5=run.f[at(5)],f15=run.f[at(15)],f30=run.f[at(30)],
      max_power=maximum(run.power[post]))
end

function svg_plot(path,title,ylabel,times,series;ymin,ymax)
    w,h,l,r,top,bottom=900,460,75,25,50,60; pw=w-l-r; ph=h-top-bottom
    sx(t)=l+pw*t/T_END; sy(y)=top+ph*(ymax-y)/(ymax-ymin)
    colors=["#1769aa","#d1495b","#2a9d8f","#7b2cbf","#f4a261","#555"]
    open(path,"w") do io
        println(io,"<svg xmlns=\"http://www.w3.org/2000/svg\" width=\"$w\" height=\"$h\" viewBox=\"0 0 $w $h\"><rect width=\"100%\" height=\"100%\" fill=\"white\"/><text x=\"$l\" y=\"30\" font-family=\"sans-serif\" font-size=\"20\">$title</text>")
        println(io,"<line x1=\"$l\" y1=\"$(top+ph)\" x2=\"$(l+pw)\" y2=\"$(top+ph)\" stroke=\"#222\"/><line x1=\"$l\" y1=\"$top\" x2=\"$l\" y2=\"$(top+ph)\" stroke=\"#222\"/>")
        for j in 0:5
            y=ymin+j*(ymax-ymin)/5; yy=sy(y); label=@sprintf("%.3f",y)
            println(io,"<line x1=\"$l\" y1=\"$yy\" x2=\"$(l+pw)\" y2=\"$yy\" stroke=\"#ddd\"/><text x=\"$(l-8)\" y=\"$(yy+4)\" text-anchor=\"end\" font-family=\"sans-serif\" font-size=\"12\">$label</text>")
        end
        for (j,(label,values)) in enumerate(series)
            pts=join(("$(round(sx(t),digits=2)),$(round(sy(y),digits=2))" for (t,y) in zip(times,values))," "); c=colors[j]
            println(io,"<polyline fill=\"none\" stroke=\"$c\" stroke-width=\"2\" points=\"$pts\"/><text x=\"$(l+15+190*(j-1))\" y=\"$(h-18)\" font-family=\"sans-serif\" font-size=\"13\" fill=\"$c\">$label</text>")
        end
        println(io,"<line x1=\"$(sx(EVENT_TIME))\" y1=\"$top\" x2=\"$(sx(EVENT_TIME))\" y2=\"$(top+ph)\" stroke=\"#777\" stroke-dasharray=\"5 5\"/><text x=\"$(w/2)\" y=\"$(h-38)\" text-anchor=\"middle\" font-family=\"sans-serif\" font-size=\"14\">Time [s]</text><text x=\"18\" y=\"$(h/2)\" transform=\"rotate(-90 18 $(h/2))\" text-anchor=\"middle\" font-family=\"sans-serif\" font-size=\"14\">$ylabel</text></svg>")
    end
end

out=joinpath(@__DIR__,"results"); mkpath(out)
standard=simulate(:standard;droop=0.05,Tg=0.40)
transient=simulate(:transient;droop=0.10,Tr=1.75)

open(joinpath(out,"timeseries.csv"),"w") do io
    println(io,"time_s,standard_frequency_hz,transient_frequency_hz,standard_power_pu,transient_power_pu,standard_gate_pu,transient_gate_pu")
    for i in eachindex(standard.times)
        @printf(io,"%.2f,%.7f,%.7f,%.7f,%.7f,%.7f,%.7f\n",standard.times[i],standard.f[i],transient.f[i],standard.power[i],transient.power[i],standard.gate[i],transient.gate[i])
    end
end

cases=[("standard_R0.04_Tg0.40",:standard,0.04,0.40),("standard_R0.05_Tg0.40",:standard,0.05,0.40),("standard_R0.06_Tg0.60",:standard,0.06,0.60),("transient_R0.08_Tr1.25",:transient,0.08,1.25),("transient_R0.10_Tr1.75",:transient,0.10,1.75),("transient_R0.12_Tr2.25",:transient,0.12,2.25)]
open(joinpath(out,"parameter_sweep.csv"),"w") do io
    println(io,"case,controller,droop,time_constant_s,nadir_hz,nadir_time_s,power_5s_pu,power_15s_pu,power_30s_pu,max_power_pu")
    for (name,kind,r,tc) in cases
        run=kind==:standard ? simulate(kind;droop=r,Tg=tc) : simulate(kind;droop=r,Tr=tc); m=metrics(name,run)
        @printf(io,"%s,%s,%.3f,%.2f,%.6f,%.3f,%.6f,%.6f,%.6f,%.6f\n",name,kind,r,tc,m.nadir,m.nadir_time,m.p5,m.p15,m.p30,m.max_power)
    end
end

base=[metrics("standard_droop",standard),metrics("transient_droop",transient)]
open(joinpath(out,"metrics.csv"),"w") do io
    println(io,"controller,nadir_hz,nadir_time_s,power_5s_pu,power_15s_pu,power_30s_pu,frequency_5s_hz,frequency_15s_hz,frequency_30s_hz,max_power_pu")
    for m in base
        @printf(io,"%s,%.6f,%.3f,%.6f,%.6f,%.6f,%.6f,%.6f,%.6f,%.6f\n",m.name,m.nadir,m.nadir_time,m.p5,m.p15,m.p30,m.f5,m.f15,m.f30,m.max_power)
    end
end

fmin=min(minimum(standard.f),minimum(transient.f))-0.01
svg_plot(joinpath(out,"frequency_comparison.svg"),"10% load step: frequency response","Frequency [Hz]",standard.times,[("Standard droop",standard.f),("Transient droop",transient.f)];ymin=fmin,ymax=50.01)
svg_plot(joinpath(out,"power_comparison.svg"),"FCR active-power response","Incremental power [pu]",standard.times,[("Standard droop",standard.power),("Transient droop",transient.power)];ymin=-0.005,ymax=max(maximum(standard.power),maximum(transient.power))+0.01)

println("FCR_STUDY_OK")
for m in base
    @printf("METRIC %s nadir=%.6fHz t_nadir=%.3fs P5=%.6fpu P15=%.6fpu P30=%.6fpu Pmax=%.6fpu\n",m.name,m.nadir,m.nadir_time,m.p5,m.p15,m.p30,m.max_power)
end
println("OUTPUT_DIR=",out)
