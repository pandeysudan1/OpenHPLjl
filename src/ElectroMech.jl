# SPDX-License-Identifier: MPL-2.0
# Conceptually derived from OpenSimHub/OpenHPL ElectroMech models (MPL-2.0).

"""
    Turbine(; name, rho=1000.0, eta_h=0.9, C_v=1.0, opening=1.0,
             alpha=1.0, epsilon=5e-5)

Minimal translation of OpenHPL's simple turbine. Hydraulic flow is governed by
the BaseValve relation and shaft power is computed from hydraulic power.
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

"""
    SimpleGenerator(; name, J=2e5, poles=12, f_grid=50.0,
                     Pload=20e6, Ploss=0.0, eta_e=1.0)

Reduced translation of OpenHPL.Generators.SimpleGen using rotor energy balance.
`P_m` is left as an algebraic input so it can be connected directly to turbine
shaft power in an assembled plant model.
"""
@component function SimpleGenerator(; name,
    J = 2.0e5,
    poles = 12,
    f_grid = 50.0,
    Pload = 20.0e6,
    Ploss = 0.0,
    eta_e = 1.0)

    omega_nom = 4pi * f_grid / poles

    @variables begin
        omega(t) = omega_nom
        f(t) = f_grid
        P_m(t)
        P_e(t)
        P_fric(t)
    end

    eqs = [
        P_fric ~ Ploss * (omega / omega_nom)^2,
        J * omega * D(omega) ~ P_m - Pload - P_fric,
        f ~ omega * poles / (4pi),
        P_e ~ eta_e * Pload,
    ]

    ODESystem(eqs, t, [omega, f, P_m, P_e, P_fric], []; name = name)
end
