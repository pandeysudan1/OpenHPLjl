"""
    ReducedSMIB

Runnable control-oriented SMIB assembled from:
frequency sensor -> droop governor -> gate servo -> torque actuator -> shaft ->
classical rotor -> SMIB network.

The servo output is interpreted as mechanical torque through gain Ktau.
"""
@component function ReducedSMIB(;
    name,
    omega0 = 2*pi*50,
    J = 1.0e5,
    damping = 2.0e3,
    R = 0.05,
    Tg = 0.2,
    y0 = 0.5,
    Ktau = 2.0e3,
    Pmax = 3.0e5,
    delta0 = 0.2,
)
    @named shaft = LumpedShaft(J=J, damping=damping, omega0=omega0)
    @named sensor = FrequencySensor()
    @named governor = DroopGovernor(omega_ref=omega0, y0=y0, R=R)
    @named servo = GateServo(Tg=Tg, y0=y0)
    @named torque = MechanicalTorqueActuator()
    @named generator = ClassicalGeneratorRotor(omega_s=omega0, delta0=delta0)
    @named grid = SMIBNetwork(Pmax=Pmax)

    @parameters Ktau=Ktau

    eqs = [
        connect(shaft.drive, sensor.port)
        connect(sensor.y, governor.omega)
        connect(governor.y_cmd, servo.cmd)
        torque.cmd.u ~ Ktau * servo.y.u
        connect(torque.shaft, shaft.drive)
        connect(generator.shaft, shaft.load)
        connect(generator.delta, grid.delta)
        connect(grid.Pe, generator.Pe)
    ]

    System(
        eqs, t, [], [Ktau];
        systems=[shaft,sensor,governor,servo,torque,generator,grid],
        name=name,
    )
end
