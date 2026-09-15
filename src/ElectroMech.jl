# SPDX-License-Identifier: MPL-2.0
# Conceptually derived from OpenSimHub/OpenHPL ElectroMech and Controller models (MPL-2.0).

"""
    Turbine(; name, rho=1000.0, eta_h=0.9, C_v=1.0, opening=1.0,
             alpha=1.0, epsilon=5e-5, use_opening_input=false)

Minimal translation of OpenHPL's simple turbine. When `use_opening_input=false`,
`u` is fixed to `opening`. When true, the assembled plant must provide one
equation for `u`, e.g. `turbine.u ~ governor.u`.
"""
@component function Turbine(; name,
    rho = 1000.0,
    eta_h = 0.9,
    C_v = 1.0,
    opening = 1.0,
    alpha = 1.0,
    epsilon = 5.0e-5,
    use_opening_input = false)

    @named i = Contact()
    @named o = Contact()

    @variables begin
        u(t) = opening
        mdot(t)
        Vdot(t)
        dp(t)
        P_hyd(t)
        P_t(t)
    end

    eqs = Equation[
        i.mdot + o.mdot ~ 0,
        mdot ~ i.mdot,
        Vdot ~ mdot / rho,
        dp ~ i.p - o.p,
        dp * (C_v * max(epsilon, u^alpha))^2 ~ Vdot * abs(Vdot),
        P_hyd ~ dp * Vdot,
        P_t ~ eta_h * P_hyd,
        o.z ~ i.z,
    ]

    if !use_opening_input
        push!(eqs, u ~ opening)
    end

    sys = ODESystem(eqs, t, [u, mdot, Vdot, dp, P_hyd, P_t], []; name = name)
    return compose(sys, i, o)
end

"""
    SimpleGenerator(; name, J=2e5, poles=12, f_grid=50.0,
                     Pload=20e6, Ploss=0.0, eta_e=1.0,
                     use_load_input=false)

Reduced translation of OpenHPL.Generators.SimpleGen using rotor energy balance.
When `use_load_input=true`, the assembled plant must provide `P_load`.
"""
@component function SimpleGenerator(; name,
    J = 2.0e5,
    poles = 12,
    f_grid = 50.0,
    Pload = 20.0e6,
    Ploss = 0.0,
    eta_e = 1.0,
    use_load_input = false)

    omega_nom = 4pi * f_grid / poles

    @variables begin
        omega(t) = omega_nom
        f(t) = f_grid
        P_m(t)
        P_load(t) = Pload
        P_e(t)
        P_fric(t)
    end

    eqs = Equation[
        P_fric ~ Ploss * (omega / omega_nom)^2,
        J * omega * D(omega) ~ P_m - P_load - P_fric,
        f ~ omega * poles / (4pi),
        P_e ~ eta_e * P_load,
    ]

    if !use_load_input
        push!(eqs, P_load ~ Pload)
    end

    ODESystem(eqs, t, [omega, f, P_m, P_load, P_e, P_fric], []; name = name)
end

"""
    SMIBGenerator(; name, H=4.0, damping=1.0, f_grid=50.0,
                   Pm0=0.8, Pmax0=1.5, delta0=asin(Pm0/Pmax0),
                   use_pm_input=false, use_pmax_input=false)

Canonical single-machine infinite-bus model in per unit. `delta` is the rotor
angle relative to the infinite bus and `omega_pu` is rotor speed in per unit.
The network is represented by the classical power-angle relation
`P_e = Pmax_e*sin(delta)`.

    d(delta)/dt = omega_b*(omega_pu - 1)
    2H*d(omega_pu)/dt = P_m - P_e - damping*(omega_pu - 1)
    P_e = Pmax_e*sin(delta)

`P_m` and `Pmax_e` can be exposed as external algebraic inputs. This allows a
hydraulic turbine to drive mechanical power later, while network disturbances
can be represented by changes in transfer capability.
"""
@component function SMIBGenerator(; name,
    H = 4.0,
    damping = 1.0,
    f_grid = 50.0,
    Pm0 = 0.8,
    Pmax0 = 1.5,
    delta0 = asin(Pm0 / Pmax0),
    use_pm_input = false,
    use_pmax_input = false)

    omega_b = 2pi * f_grid

    @variables begin
        delta(t) = delta0
        omega_pu(t) = 1.0
        f(t) = f_grid
        P_m(t) = Pm0
        Pmax_e(t) = Pmax0
        P_e(t) = Pm0
    end

    eqs = Equation[
        D(delta) ~ omega_b * (omega_pu - 1.0),
        2H * D(omega_pu) ~ P_m - P_e - damping * (omega_pu - 1.0),
        P_e ~ Pmax_e * sin(delta),
        f ~ f_grid * omega_pu,
    ]

    if !use_pm_input
        push!(eqs, P_m ~ Pm0)
    end
    if !use_pmax_input
        push!(eqs, Pmax_e ~ Pmax0)
    end

    ODESystem(
        eqs,
        t,
        [delta, omega_pu, f, P_m, Pmax_e, P_e],
        [];
        name = name,
    )
end

"""
    DroopGovernor(; name, f_ref=50.0, R=0.05, u0=0.8,
                   T_g=0.4, u_min=0.0, u_max=1.0)

First-order primary-frequency governor. The measured frequency `f_meas` is an
external algebraic input. The command is saturated to guide-vane limits and the
servo follows it with time constant `T_g`.

    u_cmd = sat(u0 + (f_ref - f_meas)/(R*f_ref))
    T_g*du/dt = u_cmd - u
"""
@component function DroopGovernor(; name,
    f_ref = 50.0,
    R = 0.05,
    u0 = 0.8,
    T_g = 0.4,
    u_min = 0.0,
    u_max = 1.0)

    @variables begin
        f_meas(t) = f_ref
        u_cmd(t) = u0
        u(t) = u0
    end

    eqs = [
        u_cmd ~ min(u_max, max(u_min, u0 + (f_ref - f_meas) / (R * f_ref))),
        T_g * D(u) ~ u_cmd - u,
    ]

    ODESystem(eqs, t, [f_meas, u_cmd, u], []; name = name)
end

"""
    OpenHPLGovernor(; name, f_ref=50.0, Y_ref=0.72151,
                     T_p=0.04, T_g=0.2, T_r=1.75,
                     droop=0.1, delta=0.04,
                     rate_open=0.05, rate_close=0.2)

Dynamic core of `OpenHPL.Controllers.Governor` translated to ModelingToolkit.
It retains the pilot servo, main servo, permanent droop, transient droop and
asymmetric guide-vane rate limits used by OpenHPL. The upstream power-to-opening
lookup table is deliberately kept outside this first dynamic core; `Y_ref`
represents the operating-point guide-vane opening.

The reduced equations correspond to the equations documented in the upstream
Modelica model:

    T_r*dx_r/dt + x_r = delta*Y
    e = 1 - f/f_ref - (delta*Y - x_r) + droop*(Y_ref - Y)
    T_p*dx_p/dt + x_p = e
    dY_state/dt = clamp(x_p/T_g, -rate_close, rate_open)
    Y = clamp(Y_state, 0, 1)
"""
@component function OpenHPLGovernor(; name,
    f_ref = 50.0,
    Y_ref = 0.72151,
    T_p = 0.04,
    T_g = 0.2,
    T_r = 1.75,
    droop = 0.1,
    delta = 0.04,
    rate_open = 0.05,
    rate_close = 0.2)

    @variables begin
        f_meas(t) = f_ref
        x_r(t) = delta * Y_ref
        x_p(t) = 0.0
        e(t) = 0.0
        rate_cmd(t) = 0.0
        Y_state(t) = Y_ref
        Y(t) = Y_ref
    end

    eqs = [
        T_r * D(x_r) + x_r ~ delta * Y,
        e ~ 1 - f_meas / f_ref - (delta * Y - x_r) + droop * (Y_ref - Y),
        T_p * D(x_p) + x_p ~ e,
        rate_cmd ~ min(rate_open, max(-rate_close, x_p / T_g)),
        D(Y_state) ~ rate_cmd,
        Y ~ min(1.0, max(0.0, Y_state)),
    ]

    ODESystem(
        eqs,
        t,
        [f_meas, x_r, x_p, e, rate_cmd, Y_state, Y],
        [];
        name = name,
    )
end
