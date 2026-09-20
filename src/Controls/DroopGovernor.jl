"""
    DroopGovernor(; name, f_ref=50.0, R=2.5, Tg=0.2, y0=1.0)

First-order droop governor with frequency input and guide-vane output.

The static command is

    y_cmd = y0 + (f_ref - f_meas)/R

and the actuator/governor lag is

    Tg*dy/dt = y_cmd - y

R is expressed in Hz per unit gate opening. Saturation and rate limiting are
left to higher-fidelity governor variants so this baseline remains smooth and
easy to initialize.
"""
@component function DroopGovernor(;
    name,
    f_ref = 50.0,
    R = 2.5,
    Tg = 0.2,
    y0 = 1.0,
)
    @named f_meas = SignalSocket()
    @named gate = SignalPlug()

    @parameters begin
        f_ref = f_ref
        R = R
        Tg = Tg
        y0 = y0
    end

    @variables begin
        y(t) = y0, [description = "Guide-vane command [-]"]
        y_cmd(t), [guess = y0, description = "Droop command [-]"]
    end

    eqs = [
        y_cmd ~ y0 + (f_ref - f_meas.u) / R
        Tg * D(y) ~ y_cmd - y
        gate.u ~ y
    ]

    return System(
        eqs,
        t,
        [y, y_cmd],
        [f_ref, R, Tg, y0];
        systems = [f_meas, gate],
        name = name,
    )
end
