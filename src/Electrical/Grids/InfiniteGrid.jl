"""
    InfiniteGrid(; name, f0=50.0)

Infinite-bus frequency boundary.

    omega = 2*pi*f0

The connected network determines active power P.
"""
@component function InfiniteGrid(; name, f0 = 50.0)
    @named port = ElectricalPowerPort()
    @parameters f0 = f0

    eqs = [
        port.omega ~ 2 * pi * f0
    ]

    return System(
        eqs,
        t,
        [],
        [f0];
        systems = [port],
        name = name,
    )
end
