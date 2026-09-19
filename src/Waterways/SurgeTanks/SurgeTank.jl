"""
    SurgeTank(; name, As = 100.0, H0 = 100.0)

Simple open surge tank with constant cross-sectional area.

Mass balance

    As * dH/dt = sum(Q_port)

With the OpenHPLjl connector convention, each port flow is positive into the
component. The model exposes two hydraulic ports so it can be inserted between
two waterways.

Parameters
- `As`: surge-tank free-surface area [m^2]
- `H0`: initial surge-tank level/head [m]

State
- `H(t)`: surge-tank water level/head [m]
"""
@component function SurgeTank(; name, As = 100.0, H0 = 100.0)
    @named inlet = HydraulicPort()
    @named outlet = HydraulicPort()

    @parameters begin
        As = As
        H0 = H0
    end

    @variables begin
        H(t) = H0
    end

    eqs = [
        As * D(H) ~ inlet.Q + outlet.Q
        inlet.H ~ H
        outlet.H ~ H
    ]

    return System(
        eqs,
        t,
        [H],
        [As, H0];
        systems = [inlet, outlet],
        name = name,
    )
end
