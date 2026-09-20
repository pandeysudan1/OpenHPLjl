"""
    FrequencySensor

Ideal rotational speed measurement. The sensor draws zero torque.
"""
@component function FrequencySensor(; name)
    @named port = RotationalPort()
    @named y = SignalPort()
    eqs = [
        y.u ~ port.omega
        port.tau ~ 0
    ]
    System(eqs, t, [], []; systems=[port,y], name=name)
end
