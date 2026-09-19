"""
Friction and head-loss functions used by OpenHPLjl waterways.

All head-loss functions return signed head loss [m]. For a signed volumetric
flow Q, the loss therefore has the same sign as Q.
"""

no_friction(Q; kwargs...) = zero(Q)

quadratic_head_loss(Q; R = 0.0, kwargs...) = R * Q * abs(Q)

reynolds_number(Q; D, nu, kwargs...) = 4 * abs(Q) / (pi * D * nu)

laminar_friction_factor(Re; kwargs...) = 64 / Re

haaland_friction_factor(Re; epsilon, D, kwargs...) =
    (-1.8 * log10((epsilon / (3.7 * D))^1.11 + 6.9 / Re))^(-2)

swamee_jain_friction_factor(Re; epsilon, D, kwargs...) =
    0.25 / log10(epsilon / (3.7 * D) + 5.74 / Re^0.9)^2

darcy_head_loss(Q; f, L, D, A, g = 9.81, kwargs...) =
    f * (L / D) * Q * abs(Q) / (2 * g * A^2)

function darcy_laminar_head_loss(Q; L, D, A, nu, g = 9.81, kwargs...)
    Re = reynolds_number(Q; D, nu)
    f = laminar_friction_factor(Re)
    return darcy_head_loss(Q; f, L, D, A, g)
end

function darcy_haaland_head_loss(Q; L, D, A, nu, epsilon, g = 9.81, kwargs...)
    Re = reynolds_number(Q; D, nu)
    f = haaland_friction_factor(Re; epsilon, D)
    return darcy_head_loss(Q; f, L, D, A, g)
end

function darcy_swamee_jain_head_loss(Q; L, D, A, nu, epsilon, g = 9.81, kwargs...)
    Re = reynolds_number(Q; D, nu)
    f = swamee_jain_friction_factor(Re; epsilon, D)
    return darcy_head_loss(Q; f, L, D, A, g)
end

"""
    colebrook_residual(f, Re; epsilon, D)

Residual of the implicit Colebrook-White equation.
"""
colebrook_residual(f, Re; epsilon, D) =
    1 / sqrt(f) + 2 * log10(epsilon / (3.7 * D) + 2.51 / (Re * sqrt(f)))
