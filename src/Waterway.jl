# SPDX-License-Identifier: MPL-2.0
# Hydraulic equations are derived conceptually from OpenSimHub/OpenHPL Waterway models (MPL-2.0).

@component function Reservoir(; name,
    h0 = 50.0,
    z0 = 0.0,
    L = 500.0,
    W = 100.0,
    alpha = 0.0,
    rho = 1000.0,
    g = 9.81,
    p_atm = 101325.0)

    @named o = HydraulicContact()

    @variables begin
        h(t) = h0
        A(t)
        m(t)
        Vdot_o(t)
        p_o(t)
    end

    eqs = [
        A ~ h * (W + h * tan(alpha)),
        m ~ rho * A * L,
        D(m) ~ -rho * Vdot_o,
        p_o ~ p_atm + g * rho * h,
        o.p ~ p_o,
        o.mdot ~ -rho * Vdot_o,
    ]

    sys = ODESystem(eqs, t, [h, A, m, Vdot_o, p_o], []; name = name)
    return compose(sys, o)
end

@component function ConstantLevelReservoir(; name,
    h = 50.0,
    z = 0.0,
    rho = 1000.0,
    g = 9.81,
    p_atm = 101325.0)

    @named o = HydraulicContact()

    eqs = [
        o.p ~ p_atm + rho * g * h,
    ]

    sys = ODESystem(eqs, t, [], []; name = name)
    return compose(sys, o)
end

@component function HydroPipe(; name,
    H = 0.0,
    L = 1000.0,
    D_i = 1.0,
    D_o = D_i,
    rho = 1000.0,
    mu = 1.0e-3,
    g = 9.81,
    p_eps = 1.5e-5,
    Vdot0 = 0.0)

    @named i = HydraulicContact()
    @named o = HydraulicContact()

    Dbar = (D_i + D_o) / 2
    Abar = pi * Dbar^2 / 4
    delta = 2 * (D_i - D_o) / (D_i + D_o)
    cf = 1 + 2 * delta^2

    @variables begin
        mdot(t) = rho * Vdot0
        Vdot(t) = Vdot0
        v(t) = Vdot0 / Abar
        F_f(t) = 0.0
        dp(t) = 0.0
    end

    eqs = [
        Vdot ~ mdot / rho,
        v ~ Vdot / Abar,
        F_f ~ cf * darcy_friction(v, Dbar, L, rho, mu, p_eps),
        L * D(mdot) ~ (i.p + rho * g * H - o.p) * Abar - F_f,
        dp ~ o.p - i.p,
        i.mdot ~ mdot,
        o.mdot ~ -mdot,
    ]

    sys = ODESystem(eqs, t, [mdot, Vdot, v, F_f, dp], []; name = name)
    return compose(sys, i, o)
end

@component function SurgeTank(; name,
    H = 100.0,
    L = H,
    diameter = 3.0,
    h0 = 50.0,
    Vdot0 = 0.0,
    rho = 1000.0,
    mu = 1.0e-3,
    g = 9.81,
    p_atm = 101325.0,
    p_eps = 1.5e-5)

    @named i = HydraulicContact()
    @named o = HydraulicContact()

    A = pi * diameter^2 / 4
    cos_theta = H / L

    @variables begin
        h(t) = h0
        l(t) = h0 / cos_theta
        m(t) = rho * A * h0 / cos_theta
        mdot(t) = rho * Vdot0
        Vdot(t) = Vdot0
        v(t) = Vdot0 / A
        M(t) = rho * A * h0 / cos_theta * Vdot0 / A
        F_p(t) = 0.0
        F_f(t) = 0.0
        F_g(t) = rho * A * h0 / cos_theta * g * cos_theta
        p_b(t) = p_atm + rho * g * h0
    end

    eqs = [
        i.p ~ o.p,
        p_b ~ i.p,
        mdot ~ i.mdot + o.mdot,
        Vdot ~ mdot / rho,
        v ~ Vdot / A,
        l ~ h / cos_theta,
        m ~ rho * A * l,
        M ~ m * v,
        F_p ~ (p_b - p_atm) * A,
        F_f ~ darcy_friction(v, diameter, l, rho, mu, p_eps),
        F_g ~ m * g * cos_theta,
        D(m) ~ mdot,
        D(M) ~ mdot * v + F_p - F_f - F_g,
    ]

    sys = ODESystem(
        eqs,
        t,
        [h, l, m, mdot, Vdot, v, M, F_p, F_f, F_g, p_b],
        [];
        name = name,
    )
    return compose(sys, i, o)
end

@component function PressureBoundary(; name, p = 101325.0)
    @named i = HydraulicContact()
    eqs = [i.p ~ p]
    sys = ODESystem(eqs, t, [], []; name = name)
    return compose(sys, i)
end
