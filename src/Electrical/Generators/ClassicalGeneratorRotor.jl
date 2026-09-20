"""
    ClassicalGeneratorRotor(; name, omega_s=2*pi*50, delta0=0.2)

Classical rotor-angle interface when mechanical inertia is carried by a separate
shaft model.

    ddelta/dt = omega - omega_s
    tau_e = -Pe/omega
"""
@component function ClassicalGeneratorRotor(;
    name,
    omega_s = 2*pi*50,
    delta0 = 0.2,
)
    @named shaft = RotationalPort()
    @named Pe = SignalPort()
    @named delta = SignalPort()
    @parameters omega_s=omega_s
    @variables rotor_angle(t)=delta0
    eqs = [
        D(rotor_angle) ~ shaft.omega - omega_s
        delta.u ~ rotor_angle
        shaft.tau ~ Pe.u / shaft.omega
    ]
    System(eqs, t, [rotor_angle], [omega_s]; systems=[shaft,Pe,delta], name=name)
end
