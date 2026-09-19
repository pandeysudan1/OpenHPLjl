"""
    RigidPipe(; name, friction=:quadratic, ...)

Rigid, incompressible water-column model with selectable friction law.

Momentum balance

    dQ/dt = (g*A/L) * (Hin - Hout - hf(Q))

The friction law is selected at model-construction time from
FRICTION_MODEL_REGISTRY.
"""
@component function RigidPipe(;
    name,
    friction = :quadratic,
    L = 100.0,
    A = 1.0,
    g = 9.81,
    R = 0.0,
    diameter = sqrt(4 * A / pi),
    nu = 1.0e-6,
    epsilon = 1.0e-4,
    f = 0.02,
    Q0 = 0.0,
)
    @named inlet = HydraulicPort()
    @named outlet = HydraulicPort()

    @parameters begin
        L = L
        A = A
        g = g
        R = R
        diameter = diameter
        nu = nu
        epsilon = epsilon
        f = f
    end

    @variables begin
        Q(t) = Q0
    end

    friction_fn = friction_model(friction)
    hf = friction_fn(
        Q;
        R = R,
        L = L,
        D = diameter,
        A = A,
        g = g,
        nu = nu,
        epsilon = epsilon,
        f = f,
    )

    eqs = [
        inlet.Q ~ Q
        outlet.Q ~ -Q
        D(Q) ~ (g * A / L) * (inlet.H - outlet.H - hf)
    ]

    return System(
        eqs,
        t,
        [Q],
        [L, A, g, R, diameter, nu, epsilon, f];
        systems = [inlet, outlet],
        name = name,
    )
end
