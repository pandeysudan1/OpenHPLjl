"""
Aggregate finite-inertia grid literature prototype.

Reduced frequency model:

    Mgrid*domega/dt = Pin - Pload - Dgrid*(omega-omega0)

This family represents a non-infinite surrounding grid without full network
phasor equations.
"""
struct AggregateGridSpec
    Mgrid::Float64
    Dgrid::Float64
    omega0::Float64
end
