"""
    PowerMeasurement

Ideal signal measurement / monitor.
"""
@component function PowerMeasurement(; name)
    @named input = SignalPort()
    @named y = SignalPort()
    eqs = [y.u ~ input.u]
    System(eqs, t, [], []; systems=[input,y], name=name)
end
