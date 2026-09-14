# SPDX-License-Identifier: MPL-2.0
# Reservoir equations are derived from OpenSimHub/OpenHPL Waterway.Reservoir (MPL-2.0).

"""
    Reservoir(; name, h0=50.0, z0=0.0, L=500.0, W=100.0,
               alpha=0.0, rho=1000.0, g=9.81, p_atm=101325.0)

Initial OpenHPL -> ModelingToolkit translation of the default reservoir mode.
The model is deliberately written as a DAE: storage mass and water level are
linked algebraically through reservoir geometry while mass balance supplies the
dynamic equation.

This milestone implements the default OpenHPL reservoir assumption (no external
inflow connector). More detailed `useInflow`, `useLevel`, friction/momentum and
overconstrained elevation modes are tracked in `docs/TRANSLATION_PLAN.md`.
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
