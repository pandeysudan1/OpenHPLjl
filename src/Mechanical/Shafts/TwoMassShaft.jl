"""
    TwoMassShaft(; name, J1, J2, Kt, Dt, omega0)

Prototype torsional two-mass shaft.

    J1*domega1/dt = tau_drive - Kt*(theta1-theta2) - Dt*(omega1-omega2)
    J2*domega2/dt = Kt*(theta1-theta2) + Dt*(omega1-omega2) + tau_load
    dtheta1/dt = omega1
    dtheta2/dt = omega2
"""
@component function TwoMassShaft(;
    name,
    J1=5.0e4,
    J2=5.0e4,
    Kt=1.0e6,
    Dt=1.0e3,
    omega0=2*pi*50,
)
    @named drive = RotationalPort()
    @named load = RotationalPort()
    @parameters J1=J1 J2=J2 Kt=Kt Dt=Dt omega0=omega0
    @variables begin
        theta1(t)=0.0
        theta2(t)=0.0
        omega1(t)=omega0
        omega2(t)=omega0
    end
    eqs = [
        D(theta1) ~ omega1,
        D(theta2) ~ omega2,
        J1*D(omega1) ~ drive.tau - Kt*(theta1-theta2) - Dt*(omega1-omega2),
        J2*D(omega2) ~ Kt*(theta1-theta2) + Dt*(omega1-omega2) + load.tau,
        drive.omega ~ omega1,
        load.omega ~ omega2,
    ]
    System(eqs, t, [theta1,theta2,omega1,omega2], [J1,J2,Kt,Dt,omega0];
        systems=[drive,load], name=name)
end
