# SPDX-License-Identifier: MPL-2.0
# Conceptually derived from OpenSimHub/OpenHPL ElectroMech.Turbines.Turbine and BaseValve (MPL-2.0).

"""
    Turbine(; name, rho=1000.0, eta_h=0.9, C_v=1.0, opening=1.0,
             alpha=1.0, epsilon=5e-5)

Minimal translation of OpenHPL's simple turbine. Hydraulic flow is governed by
the BaseValve relation and shaft power is computed from hydraulic power:

    dp * (C_v * max(epsilon, opening^alpha))^2 = Q * abs(Q)
    P_t = eta_h * dp * Q

This first milestone keeps guide-vane opening as a parameter. A signal connector
for governor-driven opening is added in the governor milestone.
"""
@component function Turbine(; name,
    rho = 1000.0,
    eta_h = 0.9,
    C_v = 1.0,
    opening = 1.0,
    alpha = 1.0,
    epsilon = 5.0e-5)

    @named i = Contact()
    @named o = Contact()

    ueff = max(epsilon, opening^alpha)

    @variables begin
        mdot(t)
        Vdot(t)
        dp(t)
        P_hyd(t)
        P_t(t)
    end

    eqs = [
        i.mdot + o.mdot ~ 0,
        mdot ~ i.mdot,
        Vdot ~ mdot / rho,
        dp ~ i.p - o.p,
        dp * (C_v * ueff)^2 ~ Vdot * abs(Vdot),
        P_hyd ~ dp * Vdot,
        P_t ~ eta_h * P_hyd,
        o.z ~ i.z,
    ]

    sys = ODESystem(eqs, t, [mdot, Vdot, dp, P_hyd, P_t], []; name = name)
    return compose(sys, i, o)
end
