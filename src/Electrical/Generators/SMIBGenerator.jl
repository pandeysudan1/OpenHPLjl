"""
    SMIBGenerator(; name, eta=0.98, Pmax=10e6, delta0=0.5)

Reduced synchronous generator interface for a single-machine infinite-bus model.

The shaft speed is allowed to differ dynamically from grid frequency through
the rotor-angle state:

    ddelta/dt = omega_m - omega_grid

Mechanical and electrical power satisfy

    Pm = shaft.tau*shaft.omega
    Pe = eta*Pm
    Pe = Pmax*sin(delta)

and generated electrical power leaves the component:

    grid.P = -Pe

Rotational inertia is intentionally kept in LumpedShaft, so this component
contains no duplicate swing inertia.
"""
@component function SMIBGenerator(;
    name,
    eta = 0.98,
    Pmax = 10.0e6,
    delta0 = 0.5,
)
    @named shaft = RotationalPort()
    @named grid = ElectricalPowerPort()

    @parameters begin
        eta = eta
        Pmax = Pmax
        delta0 = delta0
    end

    @variables begin
        delta(t) = delta0, [description = "Rotor electrical angle relative to grid [rad]"]
        Pm(t), [guess = 1.0e6, description = "Mechanical power into generator [W]"]
        Pe(t), [guess = 1.0e6, description = "Electrical power exported [W]"]
    end

    eqs = [
        D(delta) ~ shaft.omega - grid.omega
        Pm ~ shaft.tau * shaft.omega
        Pe ~ eta * Pm
        Pe ~ Pmax * sin(delta)
        grid.P ~ -Pe
    ]

    return System(
        eqs,
        t,
        [delta, Pm, Pe],
        [eta, Pmax, delta0];
        systems = [shaft, grid],
        name = name,
    )
end
