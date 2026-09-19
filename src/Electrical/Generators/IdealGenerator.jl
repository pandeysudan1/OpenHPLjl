"""
    IdealGenerator(; name, eta=0.98)

Reduced algebraic generator converting mechanical shaft power to electrical
active power.

    Pm = shaft.tau * shaft.omega
    Pe = eta * Pm
    grid.P = -Pe
    grid.omega = shaft.omega

Torque and electrical power use the package convention: positive into a
component.
"""
@component function IdealGenerator(; name, eta = 0.98)
    @named shaft = RotationalPort()
    @named grid = ElectricalPowerPort()

    @parameters eta = eta

    @variables begin
        Pm(t)
        Pe(t)
    end

    eqs = [
        Pm ~ shaft.tau * shaft.omega
        Pe ~ eta * Pm
        grid.P ~ -Pe
        grid.omega ~ shaft.omega
    ]

    return System(
        eqs,
        t,
        [Pm, Pe],
        [eta];
        systems = [shaft, grid],
        name = name,
    )
end
