"""
    SimpleGateTurbine(; name, rho=1000.0, g=9.81, eta=0.9, Kq=1.0, y=1.0)

Simple gate-controlled turbine model.

For positive turbine head,

    Q = Kq*y*sqrt(H)
    H = inlet.H - outlet.H
    Pm = rho*g*eta*Q*H

The guide-vane opening y is a parameter in this first version. It can later be
promoted to a causal control signal or connected control component.
"""
@component function SimpleGateTurbine(;
    name,
    rho = 1000.0,
    g = 9.81,
    eta = 0.9,
    Kq = 1.0,
    y = 1.0,
)
    @named inlet = HydraulicPort()
    @named outlet = HydraulicPort()

    @parameters begin
        rho = rho
        g = g
        eta = eta
        Kq = Kq
        y = y
    end

    @variables begin
        Q(t)
        H(t)
        Pm(t)
    end

    eqs = [
        H ~ inlet.H - outlet.H
        Q ~ Kq * y * sqrt(H)
        inlet.Q ~ Q
        outlet.Q ~ -Q
        Pm ~ rho * g * eta * Q * H
    ]

    return System(
        eqs,
        t,
        [Q, H, Pm],
        [rho, g, eta, Kq, y];
        systems = [inlet, outlet],
        name = name,
    )
end
