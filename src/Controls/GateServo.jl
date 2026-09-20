"""
    GateServo(; name, Tg=0.2, y0=0.5)

First-order guide-vane servomotor

    Tg*dy/dt = cmd - y
"""
@component function GateServo(; name, Tg=0.2, y0=0.5)
    @named cmd = SignalPort()
    @named y = SignalPort()
    @parameters Tg=Tg
    @variables gate(t)=y0
    eqs = [
        Tg * D(gate) ~ cmd.u - gate
        y.u ~ gate
    ]
    System(eqs, t, [gate], [Tg]; systems=[cmd,y], name=name)
end
