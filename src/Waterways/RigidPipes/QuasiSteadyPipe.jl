"""
    QuasiSteadyPipe(; name, R=0.0)

Algebraic conduit with no water-inertia state.

    inlet.Q + outlet.Q = 0
    inlet.H - outlet.H = R*Q*abs(Q)
"""
@component function QuasiSteadyPipe(; name, R=0.0)
    @named inlet = HydraulicPort()
    @named outlet = HydraulicPort()
    @parameters R=R
    @variables Q(t)
    eqs = [
        inlet.Q ~ Q,
        outlet.Q ~ -Q,
        inlet.H - outlet.H ~ R * Q * abs(Q),
    ]
    System(eqs, t, [Q], [R]; systems=[inlet,outlet], name=name)
end
