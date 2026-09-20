"""
    ControlledGateTurbine(; name, rho=1000.0, g=9.81, eta=0.9, Kq=1.0)

Signal-ready gate-controlled turbine.

The hydraulic network determines the turbine head while the guide-vane opening
is supplied through the causal `gate` connector. Keeping the control input
outside the physical component makes the same turbine reusable with a constant
source, governor, AGC, test signal or identified controller.

Equations

    H = inlet.H - outlet.H
    y = gate.u
    Q = Kq*y*sqrt(H)
    inlet.Q = Q
    outlet.Q = -Q
    Pm = rho*g*eta*Q*H

The intended operating region is `H >= 0`. Reversible-flow and zero-head
regularization belong in a separate higher-fidelity turbine family.
"""
@component function ControlledGateTurbine(;
    name,
    rho = 1000.0,
    g = 9.81,
    eta = 0.9,
    Kq = 1.0,
)
    @named inlet = HydraulicPort()
    @named outlet = HydraulicPort()
    @named gate = SignalSocket()

    @parameters begin
        rho = rho
        g = g
        eta = eta
        Kq = Kq
    end

    @variables begin
        Q(t), [guess = 0.0, description = "Turbine flow [m^3/s]"]
        H(t), [guess = 1.0, description = "Turbine head [m]"]
        y(t), [guess = 1.0, description = "Guide-vane opening [-]"]
        Pm(t), [guess = 0.0, description = "Mechanical power [W]"]
    end

    eqs = [
        H ~ inlet.H - outlet.H
        y ~ gate.u
        Q ~ Kq * y * sqrt(H)
        inlet.Q ~ Q
        outlet.Q ~ -Q
        Pm ~ rho * g * eta * Q * H
    ]

    return System(
        eqs,
        t,
        [Q, H, y, Pm],
        [rho, g, eta, Kq];
        systems = [inlet, outlet, gate],
        name = name,
    )
end
