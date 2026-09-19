"""
Variable-area surge-tank prototype.

    A(H)*dH/dt = sum(Q)
    A(H) = A0 + kA*(H-Href)
"""
struct VariableAreaSurgeTankSpec
    A0::Float64
    kA::Float64
    Href::Float64
end
