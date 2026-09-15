# SPDX-License-Identifier: MPL-2.0

"""
    ClassicalSynchronousGenerator(; name, Sbase=100e6, H=4.0,
        damping=1.0, f_grid=50.0, poles=12, V0=1.0,
        delta0=0.5, omega_eps=1.0e-3)

Classical synchronous generator with an acausal rotational shaft port and a
reduced active-power electrical port. The rotor mechanical speed is physical
rad/s. The electrical rotor angle `delta` evolves relative to the synchronous
reference frame.
"""
@component function ClassicalSynchronousGenerator(; name,
    Sbase = 100.0e6,
    H = 4.0,
    damping = 1.0,
    f_grid = 50.0,
    poles = 12,
    V0 = 1.0,
    delta0 = 0.5,
    omega_eps = 1.0e-3)

    pole_pairs = poles / 2
    omega_m_nom = 2pi * f_grid / pole_pairs
    J = 2H * Sbase / omega_m_nom^2

    @named mech = RotationalContact()
    @named terminal = ElectricalContact()

    # delta and omega_m are the independent generator states. Frequency,
    # electrical power and torques are algebraically derived from them.
    @variables begin
        delta(t) = delta0
        omega_m(t) = omega_m_nom
        f(t)
        P_e(t)
        tau_m(t)
        tau_e(t)
    end

    omega_safe = sqrt(omega_m^2 + omega_eps^2)

    eqs = [
        mech.omega ~ omega_m,
        D(delta) ~ pole_pairs * (omega_m - omega_m_nom),
        terminal.theta ~ delta,
        terminal.V ~ V0,
        P_e ~ -terminal.P,
        tau_m ~ mech.tau,
        tau_e ~ Sbase * P_e / omega_safe,
        J * D(omega_m) ~ tau_m - tau_e - damping * J * (omega_m - omega_m_nom),
        f ~ omega_m * pole_pairs / (2pi),
    ]

    sys = ODESystem(
        eqs,
        t,
        [delta, omega_m, f, P_e, tau_m, tau_e],
        [];
        name = name,
    )
    return compose(sys, mech, terminal)
end

"""
    LosslessLine(; name, X=0.5)

Reduced lossless active-power transmission line:

    P_ab = V_a*V_b/X * sin(theta_a - theta_b)
"""
@component function LosslessLine(; name, X = 0.5)
    @named a = ElectricalContact()
    @named b = ElectricalContact()

    @variables P_ab(t)

    eqs = [
        P_ab ~ (a.V * b.V / X) * sin(a.theta - b.theta),
        a.P ~ P_ab,
        b.P ~ -P_ab,
    ]

    sys = ODESystem(eqs, t, [P_ab], []; name = name)
    return compose(sys, a, b)
end

"""
    InfiniteBus(; name, V=1.0, theta=0.0)
"""
@component function InfiniteBus(; name, V = 1.0, theta = 0.0)
    @named terminal = ElectricalContact()

    eqs = [
        terminal.V ~ V,
        terminal.theta ~ theta,
    ]

    sys = ODESystem(eqs, t, [], []; name = name)
    return compose(sys, terminal)
end

"""
    SingleAreaGrid(; name, H=6.0, damping=1.0, f_ref=50.0,
                    V=1.0, Pload0=0.8, use_load_input=false)
"""
@component function SingleAreaGrid(; name,
    H = 6.0,
    damping = 1.0,
    f_ref = 50.0,
    V = 1.0,
    Pload0 = 0.8,
    use_load_input = false)

    omega_b = 2pi * f_ref

    @named terminal = ElectricalContact()

    @variables begin
        theta(t) = 0.0
        omega_pu(t) = 1.0
        f(t) = f_ref
        P_load(t) = Pload0
        P_in(t) = Pload0
    end

    eqs = Equation[
        terminal.V ~ V,
        terminal.theta ~ theta,
        P_in ~ terminal.P,
        D(theta) ~ omega_b * (omega_pu - 1.0),
        2H * D(omega_pu) ~ P_in - P_load - damping * (omega_pu - 1.0),
        f ~ f_ref * omega_pu,
    ]

    if !use_load_input
        push!(eqs, P_load ~ Pload0)
    end

    sys = ODESystem(
        eqs,
        t,
        [theta, omega_pu, f, P_load, P_in],
        [];
        name = name,
    )
    return compose(sys, terminal)
end
