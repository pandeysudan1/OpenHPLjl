"""
Sharp-orifice surge-tank literature prototype.

Typical orifice relation:
    DeltaH = Ko*Q*abs(Q)

combined with tank storage:
    As*dH/dt = Q
"""
struct OrificeSurgeTankSpec
    area::Float64
    orifice_coefficient::Float64
end
