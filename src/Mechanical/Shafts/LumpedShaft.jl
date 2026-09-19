"""
    LumpedShaft(; name, J=1.0e5, damping=0.0, omega0=2*pi*50)

Single-inertia shaft with two rotational ports.

    J*domega/dt = drive.tau + load.tau - damping*(omega-omega0)

Both port torques are positive into the shaft.
"""
@component function LumpedShaft(;
    name,
    J = 1.0e5,
    damping = 0.0,
    omega0 = 2 * pi * 50,
)
    @named drive = RotationalPort()
    @named load = RotationalPort()

    @parameters begin
        J = J
        damping = damping
        omega0 = omega0
    end

    @variables begin
        omega(t) = omega0
    end

    eqs = [
        J * D(omega) ~ drive.tau + load.tau - damping * (omega - omega0)
        drive.omega ~ omega
        load.omega ~ omega
    ]

    return System(
        eqs,
        t,
        [omega],
        [J, damping, omega0];
        systems = [drive, load],
        name = name,
    )
end
