"""
SMIBGrid literature prototype.

Single-machine infinite-bus network using the classical power-angle relation

    Pe = E*V/X * sin(delta)

or a richer algebraic network if transient-emf states are present.

Requires generator rotor angle and/or a phasor connector; retained as a
literature prototype until those interfaces are activated.
"""
struct SMIBGridSpec
    Vinf::Float64
    Xeq::Float64
end
