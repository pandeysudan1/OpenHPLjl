"""
    blended_friction_factor(Re; epsilon, D, Re_lam=2000, Re_turb=4000)

Smoothly blends laminar 64/Re and Haaland turbulent friction factors across the
transition region. Intended as a numerically convenient literature-family
prototype.
"""
function blended_friction_factor(Re; epsilon, D, Re_lam=2000.0, Re_turb=4000.0)
    fl = 64 / Re
    ft = haaland_friction_factor(Re; epsilon, D)
    Re <= Re_lam && return fl
    Re >= Re_turb && return ft
    s = (Re - Re_lam) / (Re_turb - Re_lam)
    w = s^2 * (3 - 2s)
    return (1 - w) * fl + w * ft
end
