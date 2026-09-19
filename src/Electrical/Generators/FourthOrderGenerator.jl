"""
Fourth-order synchronous-generator literature prototype.

Typical states:
    delta, omega, Eqp, Edp

with swing equations plus transient emf dynamics:

    Tdo_p*dEqp/dt = Efd - Eqp - (Xd-Xd_p)*Id
    Tqo_p*dEdp/dt = -Edp + (Xq-Xq_p)*Iq

Requires a phasor voltage/current connector and dq network algebra.
"""
struct FourthOrderGeneratorSpec
    H::Float64
    D::Float64
    Xd::Float64
    Xq::Float64
    Xd_p::Float64
    Xq_p::Float64
    Tdo_p::Float64
    Tqo_p::Float64
end
