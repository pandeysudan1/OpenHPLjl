"""
    ShaftCoupledTurbine(; name, rho=1000.0, g=9.81, eta=0.9, Kq=1.0)

Hydraulic turbine with a causal gate input and an acausal rotational shaft port.

Equations

    H = inlet.H - outlet.H
    y = gate.u
    Q = Kq*y*sqrt(H)
    P_h = rho*g*eta*Q*H
    shaft.tau*shaft.omega = -P_h

The negative sign follows the package convention that flow variables are
positive into a component: a generating turbine exports mechanical power
through its shaft port.

This baseline assumes positive turbine head. Reversible operation, zero-head
regularization, characteristic maps and efficiency surfaces belong to richer
model families.
"""
@component function ShaftCoupledTurbine(;
    name,
    rho = 1000.0,
    g = 9.81,
    eta = 0.9,
    Kq = 1.0,
)
    @named inlet = HydraulicPort()
    @named outlet = HydraulicPort()
    @named gate = SignalSocket()
    @named shaft = RotationalPort()

    @parameters begin
        rho = rho
        g = g
        eta = eta
        Kq = Kq
    end

    @variables begin
        Q(t), [guess = 1.0, description = "Turbine flow [m^3/s]"]
        H(t), [guess = 100.0, description = "Turbine head [m]"]
        y(t), [guess = 1.0, description = "Guide-vane opening [-]"]
        Ph(t), [guess = 1.0e6, description = "Mechanical power exported by turbine [W]"]
    end

    eqs = [
        H ~ inlet.H - outlet.H
        y ~ gate.u
        Q ~ Kq * y * sqrt(H)
        inlet.Q ~ Q
        outlet.Q ~ -Q
        Ph ~ rho * g * eta * Q * H
        shaft.tau * shaft.omega ~ -Ph
    ]

    return System(
        eqs,
        t,
        [Q, H, y, Ph],
        [rho, g, eta, Kq];
        systems = [inlet, outlet, gate, shaft],
        name = name,
    )
end
