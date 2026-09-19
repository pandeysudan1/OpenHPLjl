"""
ElasticPenstock literature prototype.

The elastic waterway is governed by coupled continuity and momentum equations

    dH/dt + a^2/(g*A) * dQ/dx = 0
    dH/dx + 1/(g*A) * dQ/dt + friction = 0

This file records the model family and intended semi-discrete state structure.
A production implementation should discretize the spatial coordinate and expose
the same HydraulicPort endpoints as RigidPipe.
"""
struct ElasticPenstockSpec
    n_cells::Int
    wave_speed::Float64
end
