"""
    InfiniteReservoir(; name, H0 = 100.0)

Constant-head reservoir boundary.

Mathematical model

    H_port = H0

The reservoir has no dynamic state. The connected hydraulic network determines
the flow through `port.Q`.
"""
@component function InfiniteReservoir(; name, H0 = 100.0)
    @named port = HydraulicPort()
    @parameters H0 = H0

    eqs = [
        port.H ~ H0
    ]

    return System(
        eqs,
        t,
        [],
        [H0];
        systems = [port],
        name = name,
    )
end
