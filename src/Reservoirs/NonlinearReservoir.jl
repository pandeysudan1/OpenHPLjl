"""
    NonlinearReservoir(; name, A0=1e6, kA=0.0, Href=100.0, H0=100.0, Qin=0.0)

Prototype nonlinear area-elevation reservoir.

    A(H) = A0 + kA*(H-Href)
    A(H)*dH/dt = Qin + port.Q
"""
@component function NonlinearReservoir(;
    name, A0=1.0e6, kA=0.0, Href=100.0, H0=100.0, Qin=0.0,
)
    @named port = HydraulicPort()
    @parameters A0=A0 kA=kA Href=Href Qin=Qin
    @variables H(t)=H0
    Aeff = A0 + kA * (H - Href)
    eqs = [Aeff * D(H) ~ Qin + port.Q, port.H ~ H]
    System(eqs, t, [H], [A0,kA,Href,Qin]; systems=[port], name=name)
end
