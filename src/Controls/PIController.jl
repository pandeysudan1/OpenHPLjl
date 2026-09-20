"""
    PIController(; name, kp=1.0, ki=0.1, ref=0.0, x0=0.0)

Generic PI controller:
    e = ref - measurement
    dx/dt = e
    output = kp*e + ki*x
"""
@component function PIController(; name, kp=1.0, ki=0.1, ref=0.0, x0=0.0)
    @named measurement = SignalPort()
    @named output = SignalPort()
    @parameters kp=kp ki=ki ref=ref
    @variables x(t)=x0 e(t)
    eqs = [
        e ~ ref - measurement.u
        D(x) ~ e
        output.u ~ kp*e + ki*x
    ]
    System(eqs, t, [x,e], [kp,ki,ref]; systems=[measurement,output], name=name)
end
