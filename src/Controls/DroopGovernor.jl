"""
    DroopGovernor(; name, omega_ref=2*pi*50, y0=0.5, R=0.05)

Static primary-frequency droop law

    y_cmd = y0 - (omega/omega_ref - 1)/R

A positive frequency deviation reduces guide-vane command.
"""
@component function DroopGovernor(;
    name,
    omega_ref = 2*pi*50,
    y0 = 0.5,
    R = 0.05,
)
    @named omega = SignalPort()
    @named y_cmd = SignalPort()
    @parameters omega_ref=omega_ref y0=y0 R=R
    eqs = [
        y_cmd.u ~ y0 - ((omega.u / omega_ref) - 1) / R
    ]
    System(eqs, t, [], [omega_ref,y0,R]; systems=[omega,y_cmd], name=name)
end
