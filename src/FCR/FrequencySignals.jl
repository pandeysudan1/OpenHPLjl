"""
    RampFrequencySignal(; name, f_start=49.9, f_end=49.0, t_start=5.0, ramp_time=3.75)

Piecewise-linear frequency source. Before `t_start` the output is `f_start`.
It then ramps linearly to `f_end` over `ramp_time` and holds.
"""
@component function RampFrequencySignal(;
    name,
    f_start = 49.9,
    f_end = 49.0,
    t_start = 5.0,
    ramp_time = 3.75,
)
    ramp_time > 0 || throw(ArgumentError("ramp_time must be positive"))

    @named y = SignalPlug()
    @parameters begin
        f_start = f_start
        f_end = f_end
        t_start = t_start
        ramp_time = ramp_time
    end

    frac = (t - t_start) / ramp_time
    fexpr = ifelse(
        t <= t_start,
        f_start,
        ifelse(t >= t_start + ramp_time, f_end, f_start + (f_end - f_start) * frac),
    )

    eqs = [y.u ~ fexpr]

    return System(
        eqs,
        t,
        [],
        [f_start, f_end, t_start, ramp_time];
        systems = [y],
        name = name,
    )
end

"""
    SineFrequencySignal(; name, f_center=50.0, amplitude=0.1, period=60.0, t_start=5.0)

Sinusoidal frequency source used for FCR sine tests. Before `t_start`, the
output equals `f_center`; afterwards it is a sine wave about that center.
"""
@component function SineFrequencySignal(;
    name,
    f_center = 50.0,
    amplitude = 0.1,
    period = 60.0,
    t_start = 5.0,
)
    period > 0 || throw(ArgumentError("period must be positive"))

    @named y = SignalPlug()
    @parameters begin
        f_center = f_center
        amplitude = amplitude
        period = period
        t_start = t_start
    end

    omega = 2 * pi / period
    fexpr = ifelse(t <= t_start, f_center, f_center + amplitude * sin(omega * (t - t_start)))
    eqs = [y.u ~ fexpr]

    return System(
        eqs,
        t,
        [],
        [f_center, amplitude, period, t_start];
        systems = [y],
        name = name,
    )
end
