# SPDX-License-Identifier: MPL-2.0
# Hydraulic equations are derived conceptually from OpenSimHub/OpenHPL Waterway models (MPL-2.0).

"""
    Reservoir(; name, h0=50.0, z0=0.0, L=500.0, W=100.0,
               alpha=0.0, rho=1000.0, g=9.81, p_atm=101325.0)

Initial OpenHPL -> ModelingToolkit translation of the default reservoir mode.
The model is deliberately written as a DAE: storage mass and water level are
linked algebraically through reservoir geometry while mass balance supplies the
dynamic equation.
"""
@component function Reservoir(; name,
    h0 = 50.0,
    z0 = 0.0,
    L = 500.0,
    W = 100.0,
    alpha = 0.0,
    rho = 1000.0,
    g = 9.81,
    p_atm = 101325.0)

    @named o = Contact()

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
        o.z ~ z0,
    ]

    sys = ODESystem(eqs, t, [h, A, m, Vdot_o, p_o], []; name = name)
    return compose(sys, o)
end

"""
    Pipe(; name, H=0.0, L=1000.0, D_i=1.0, D_o=D_i,
          rho=1000.0, mu=1.0e-3, g=9.81, p_eps=1.5e-5, Vdot0=0.0)

Translation of OpenHPL.Waterway.Pipe. The model assumes incompressible water and
inelastic pipe walls. The single dynamic state is mass flow; pressure at each
end is supplied by the connected hydraulic network.

OpenHPL momentum balance:

    L*d(mdot)/dt = (p_i + rho*g*H - p_o)*A - F_f

where `F_f` uses the same Darcy friction law as the Modelica implementation.
"""
@component function Pipe(; name,
    H = 0.0,
    L = 1000.0,
    D_i = 1.0,
    D_o = D_i,
    rho = 1000.0,
    mu = 1.0e-3,
    g = 9.81,
    p_eps = 1.5e-5,
    Vdot0 = 0.0)

    @named i = Contact()
    @named o = Contact()

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
        o.z ~ i.z - H,
    ]

    sys = ODESystem(eqs, t, [mdot, Vdot, v, F_f, dp], []; name = name)
    return compose(sys, i, o)
end

"""
    PressureBoundary(; name, p=101325.0, z=0.0)

Ideal hydraulic pressure boundary. It fixes pressure and elevation while the
connected network determines mass flow. This small component is primarily for
validation examples and will later be complemented by a translated OpenHPL
tailrace/reservoir boundary.
"""
@component function PressureBoundary(; name, p = 101325.0, z = 0.0)
    @named i = Contact()
    eqs = [
        i.p ~ p,
        i.z ~ z,
    ]
    sys = ODESystem(eqs, t, [], []; name = name)
    return compose(sys, i)
end
