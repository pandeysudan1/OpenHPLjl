# SPDX-License-Identifier: MPL-2.0
# Derived from OpenSimHub/OpenHPL Functions.DarcyFriction (MPL-2.0).

"""
    darcy_factor(Re, D, p_eps)

Darcy friction factor following OpenHPL's laminar / transition / turbulent
piecewise formulation.
"""
function darcy_factor(Re::Real, D_h::Real, p_eps::Real)
    Re_lam = 2100.0
    Re_tur = 2300.0

    if Re <= 0
        return 0.0
    elseif Re <= Re_lam
        return 64.0 / Re
    elseif Re < Re_tur
        X = [
            Re_lam^3 Re_lam^2 Re_lam 1.0;
            Re_tur^3 Re_tur^2 Re_tur 1.0;
            3Re_lam^2 2Re_lam 1.0 0.0;
            3Re_tur^2 2Re_tur 1.0 0.0
        ]
        Y = [
            64.0 / Re_lam,
            1.0 / (2log10(p_eps / (3.7D_h) + 5.74 / Re_tur^0.9))^2,
            -64.0 / Re_lam^2,
            -0.25 * 0.316 / Re_tur^1.25,
        ]
        K = X \ Y
        return K[1] * Re^3 + K[2] * Re^2 + K[3] * Re + K[4]
    else
        arg = p_eps / (3.7D_h) + 5.74 / (Re + eps(Float64))^0.9
        return 1.0 / (2log10(arg))^2
    end
end

"""
    darcy_friction(v, D, L, rho, mu, p_eps)

Signed Darcy-Weisbach friction force used by OpenHPL's simple Pipe model.
"""
function darcy_friction(v::Real, D_h::Real, L::Real, rho::Real, mu::Real, p_eps::Real)
    Re = rho * abs(v) * D_h / mu
    f = darcy_factor(Re, D_h, p_eps)
    return 0.5 * pi * f * rho * L * v * abs(v) * D_h / 4.0
end

# Keep the hydraulic friction function opaque to symbolic simplification while
# allowing generated numerical functions to evaluate the same OpenHPL law.
@register_symbolic darcy_friction(v, D_h, L, rho, mu, p_eps)
