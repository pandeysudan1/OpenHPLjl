"""
    IdealTurbine(; name, rho=1000.0, g=9.81, eta=1.0)

Hydraulic-to-mechanical power conversion with prescribed hydraulic flow from the
surrounding network.

Equations

    Q = inlet.Q
    outlet.Q = -Q
    H = inlet.H - outlet.H
    Pm = rho*g*eta*Q*H

This model does not impose a flow law. The connected hydraulic network
determines Q.
"""
@component function IdealTurbine(; name, rho = 1000.0, g = 9.81, eta = 1.0)
    @named inlet = HydraulicPort()
    @named outlet = HydraulicPort()

    @parameters begin
        rho = rho
        g = g
        eta = eta
    end

    @variables begin
        Q(t)
        H(t)
        Pm(t)
    end

    eqs = [
        Q ~ inlet.Q
        outlet.Q ~ -Q
        H ~ inlet.H - outlet.H
        Pm ~ rho * g * eta * Q * H
    ]

    return System(
        eqs,
        t,
        [Q, H, Pm],
        [rho, g, eta];
        systems = [inlet, outlet],
        name = name,
    )
end
