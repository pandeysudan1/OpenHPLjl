# SPDX-License-Identifier: MPL-2.0
# Conceptually derived from OpenSimHub/OpenHPL simple turbine and BaseValve models.

"""
    HydroTurbineShaft(; name, rho=1000.0, eta_h=0.9, C_v=1.0,
        opening=1.0, alpha=1.0, epsilon=5e-5,
        use_opening_input=false, omega_eps=1e-3)

Nonlinear hydraulic turbine with two hydraulic contacts and one rotational
shaft contact. It preserves the OpenHPL simple valve relation

    dp * (C_v * max(epsilon, u^alpha))^2 = Q*abs(Q)

and converts hydraulic power to shaft torque through

    P_t = eta_h * dp * Q
    tau_t = P_t / omega.

The shaft flow sign is chosen so a connected generator receives positive prime-
mover torque.
"""
@component function HydroTurbineShaft(; name,
    rho = 1000.0,
    eta_h = 0.9,
    C_v = 1.0,
    opening = 1.0,
    alpha = 1.0,
    epsilon = 5.0e-5,
    use_opening_input = false,
    omega_eps = 1.0e-3)

    @named i = HydraulicContact()
    @named o = HydraulicContact()
    @named shaft = RotationalContact()

    @variables begin
        u(t) = opening
        mdot(t)
        Vdot(t)
        dp(t)
        P_hyd(t)
        P_t(t)
        tau_t(t)
    end

    omega_safe = sqrt(shaft.omega^2 + omega_eps^2)

    eqs = Equation[
        i.mdot + o.mdot ~ 0,
        mdot ~ i.mdot,
        Vdot ~ mdot / rho,
        dp ~ i.p - o.p,
        dp * (C_v * max(epsilon, u^alpha))^2 ~ Vdot * abs(Vdot),
        P_hyd ~ dp * Vdot,
        P_t ~ eta_h * P_hyd,
        tau_t ~ P_t / omega_safe,
        shaft.tau ~ -tau_t,
        o.z ~ i.z,
    ]

    if !use_opening_input
        push!(eqs, u ~ opening)
    end

    sys = ODESystem(
        eqs,
        t,
        [u, mdot, Vdot, dp, P_hyd, P_t, tau_t],
        [];
        name = name,
    )
    return compose(sys, i, o, shaft)
end
