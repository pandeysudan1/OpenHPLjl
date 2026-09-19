"""
    Reservoir(; name, A = 1.0e6, H0 = 100.0, Qin = 0.0)

Finite, constant-area reservoir.

Mass conservation is

    A*dH/dt = Qin + Q_port

because the HydraulicPort convention defines `Q_port > 0` as flow into the
component. During normal generation from the reservoir, `port.Q < 0`.

Parameters
- `A`: free-surface area [m^2]
- `H0`: initial reservoir head [m]
- `Qin`: external inflow [m^3/s]

State
- `H(t)`: reservoir head [m]
"""
@component function Reservoir(; name, A = 1.0e6, H0 = 100.0, Qin = 0.0)
    @named port = HydraulicPort()

    @parameters begin
        A = A
        H0 = H0
        Qin = Qin
    end

    @variables begin
        H(t) = H0
    end

    eqs = [
        A * D(H) ~ Qin + port.Q
        port.H ~ H
    ]

    return System(
        eqs,
        t,
        [H],
        [A, H0, Qin];
        systems = [port],
        name = name,
    )
end
