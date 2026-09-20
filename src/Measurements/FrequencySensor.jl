"""
    FrequencySensor(; name)

Non-loading rotational speed sensor.

The rotational port reads shaft speed while imposing zero torque. The causal
output signal is frequency in hertz:

    f = omega / (2*pi)
"""
@component function FrequencySensor(; name)
    @named port = RotationalPort()
    @named y = SignalPlug()

    @variables f(t) [guess = 50.0, description = "Measured frequency [Hz]"]

    eqs = [
        port.tau ~ 0
        f ~ port.omega / (2 * pi)
        y.u ~ f
    ]

    return System(
        eqs,
        t,
        [f],
        [];
        systems = [port, y],
        name = name,
    )
end
