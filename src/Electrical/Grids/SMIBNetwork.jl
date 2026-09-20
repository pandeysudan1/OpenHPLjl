"""
    SMIBNetwork(; name, Pmax=1.0e6, delta_grid=0.0)

Classical lossless SMIB power-angle relation:
    Pe = Pmax*sin(delta - delta_grid)
"""
@component function SMIBNetwork(; name, Pmax=1.0e6, delta_grid=0.0)
    @named delta = SignalPort()
    @named Pe = SignalPort()
    @parameters Pmax=Pmax delta_grid=delta_grid
    eqs = [
        Pe.u ~ Pmax * sin(delta.u - delta_grid)
    ]
    System(eqs, t, [], [Pmax,delta_grid]; systems=[delta,Pe], name=name)
end
