# SPDX-License-Identifier: MPL-2.0

"""
    PowerToTorque(; name, P0=1.0e6, use_power_input=false, omega_eps=1.0e-3)

Mechanical power-to-torque adapter. Positive `P` means a prime mover is
supplying power to the shaft. The connector flow sign is chosen so a connected
generator receives positive torque.

    tau = P / omega

A smooth nonzero denominator is used close to zero speed.
"""
@component function PowerToTorque(; name,
    P0 = 1.0e6,
    use_power_input = false,
    omega_eps = 1.0e-3)

    @named shaft = RotationalContact()

    @variables begin
        P(t) = P0
        tau(t)
    end

    omega_safe = sqrt(shaft.omega^2 + omega_eps^2)

    eqs = Equation[
        tau ~ P / omega_safe,
        shaft.tau ~ -tau,
    ]

    if !use_power_input
        push!(eqs, P ~ P0)
    end

    sys = ODESystem(eqs, t, [P, tau], []; name = name)
    return compose(sys, shaft)
end

"""
    RigidShaft(; name)

Ideal rotational coupling with two acausal ports. Angle and speed are equal and
transmitted torque balances through the shaft. The component is useful as an
explicit topology element between turbine and generator models.
"""
@component function RigidShaft(; name)
    @named a = RotationalContact()
    @named b = RotationalContact()

    eqs = [
        a.phi ~ b.phi,
        a.omega ~ b.omega,
        a.tau + b.tau ~ 0,
    ]

    sys = ODESystem(eqs, t, [], []; name = name)
    return compose(sys, a, b)
end
