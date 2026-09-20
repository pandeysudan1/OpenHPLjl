"""
    FrequencyTestGrid(; name)

Infinite-bus active-power boundary whose frequency is supplied by a causal signal.

Use this component in FCR test assemblies instead of `InfiniteGrid`.
"""
@component function FrequencyTestGrid(; name)
    @named port = ElectricalPowerPort()
    @named f_cmd = SignalSocket()

    @variables f(t) [guess = 50.0, description = "Commanded grid frequency [Hz]"]

    eqs = [
        f ~ f_cmd.u
        port.omega ~ 2 * pi * f
    ]

    return System(
        eqs,
        t,
        [f],
        [];
        systems = [port, f_cmd],
        name = name,
    )
end
