"""
    ReducedSMIB(; name, ...)

Complete reduced hydropower single-machine infinite-bus assembly.

Architecture

    upstream reservoir
      -> headrace
      -> surge tank
      -> penstock
      -> shaft-coupled turbine
      -> tailwater reservoir

    turbine -> shaft -> synchronous generator -> infinite grid
                  |                         
                  -> frequency sensor -> droop governor -> turbine gate

The default operating point is constructed to be internally consistent for the
frictionless baseline: equal steady flow through both water columns, constant
surge-tank head, 50 Hz shaft speed, balanced turbine/generator power, and a
governor command equal to the initial gate opening.
"""
@component function ReducedSMIB(;
    name,
    Hup = 120.0,
    Hdown = 20.0,
    Q0 = 10.0,
    y0 = 1.0,
    rho = 1000.0,
    g = 9.81,
    eta_t = 0.90,
    eta_g = 0.98,
    Pmax = 10.0e6,
    f0 = 50.0,
    J = 1.0e5,
    damping = 0.0,
    As = 500.0,
    L_headrace = 300.0,
    A_headrace = 10.0,
    L_penstock = 500.0,
    A_penstock = 5.0,
    R_droop = 2.5,
    Tg = 0.2,
)
    Ht0 = Hup - Hdown
    Ht0 > 0 || throw(ArgumentError("ReducedSMIB requires Hup > Hdown"))
    y0 > 0 || throw(ArgumentError("ReducedSMIB requires y0 > 0"))
    Pmax > 0 || throw(ArgumentError("ReducedSMIB requires Pmax > 0"))

    Kq0 = Q0 / (y0 * sqrt(Ht0))
    Ph0 = rho * g * eta_t * Q0 * Ht0
    Pe0 = eta_g * Ph0
    Pe0 < Pmax || throw(ArgumentError("Pmax must exceed the initial electrical power"))
    delta0 = asin(Pe0 / Pmax)
    omega0 = 2 * pi * f0

    @named upstream = InfiniteReservoir(H0 = Hup)
    @named headrace = RigidPipe(
        friction = :none,
        L = L_headrace,
        A = A_headrace,
        g = g,
        Q0 = Q0,
    )
    @named surge = SurgeTank(As = As, H0 = Hup)
    @named penstock = RigidPipe(
        friction = :none,
        L = L_penstock,
        A = A_penstock,
        g = g,
        Q0 = Q0,
    )
    @named turbine = ShaftCoupledTurbine(
        rho = rho,
        g = g,
        eta = eta_t,
        Kq = Kq0,
    )
    @named tailwater = InfiniteReservoir(H0 = Hdown)

    @named shaft = LumpedShaft(
        J = J,
        damping = damping,
        omega0 = omega0,
    )
    @named generator = SMIBGenerator(
        eta = eta_g,
        Pmax = Pmax,
        delta0 = delta0,
    )
    @named grid = InfiniteGrid(f0 = f0)

    @named frequency_sensor = FrequencySensor()
    @named governor = DroopGovernor(
        f_ref = f0,
        R = R_droop,
        Tg = Tg,
        y0 = y0,
    )

    eqs = [
        connect(upstream.port, headrace.inlet)
        connect(headrace.outlet, surge.inlet)
        connect(surge.outlet, penstock.inlet)
        connect(penstock.outlet, turbine.inlet)
        connect(turbine.outlet, tailwater.port)
        connect(turbine.shaft, shaft.drive)
        connect(shaft.load, generator.shaft, frequency_sensor.port)
        connect(generator.grid, grid.port)
        connect(frequency_sensor.y, governor.f_meas)
        connect(governor.gate, turbine.gate)
    ]

    systems = [
        upstream,
        headrace,
        surge,
        penstock,
        turbine,
        tailwater,
        shaft,
        generator,
        grid,
        frequency_sensor,
        governor,
    ]

    return System(eqs, t; systems = systems, name = name)
end
