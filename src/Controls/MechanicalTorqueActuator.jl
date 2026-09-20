"""
    MechanicalTorqueActuator

Converts a scalar torque command into a rotational-port torque source.
"""
@component function MechanicalTorqueActuator(; name)
    @named cmd = SignalPort()
    @named shaft = RotationalPort()
    eqs = [
        shaft.tau ~ -cmd.u
    ]
    System(eqs, t, [], []; systems=[cmd,shaft], name=name)
end
