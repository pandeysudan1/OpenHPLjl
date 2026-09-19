"""
    RigidPipe(; name, L=100.0, A=1.0, g=9.81, R=0.0, Q0=0.0)

Rigid, incompressible water-column model with quadratic head loss.

Equations

    inlet.Q  = Q
    outlet.Q = -Q
    dQ/dt = (g*A/L) * (inlet.H - outlet.H - R*Q*abs(Q))

The HydraulicPort convention defines flow as positive into a component.
"""
@component function RigidPipe(;
    name,
    L = 100.0,
    A = 1.0,
    g = 9.81,
    R = 0.0,
    Q0 = 0.0,
)
    @named inlet = HydraulicPort()
    @named outlet = HydraulicPort()

    @parameters begin
        L = L
        A = A
        g = g
        R = R
    end

    @variables begin
        Q(t) = Q0
    end

    eqs = [
        inlet.Q ~ Q
        outlet.Q ~ -Q
        D(Q) ~ (g * A / L) * (inlet.H - outlet.H - R * Q * abs(Q))
    ]

    return System(
        eqs,
        t,
        [Q],
        [L, A, g, R];
        systems = [inlet, outlet],
        name = name,
    )
end
