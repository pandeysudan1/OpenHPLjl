using OpenHPLjl
using ModelingToolkit
using OrdinaryDiffEq
using SciMLBase

# Full component-wise nonlinear hydro FCR study
#
# ConstantLevelReservoir -> Headrace -> SurgeTank -> Penstock -> HydroTurbineShaft
#                                                            |
#                                                    RotationalContact
#                                                            |
#                                             ClassicalSynchronousGenerator
#                                                            |
#                                                    ElectricalContact
#                                                            |
#                                                      LosslessLine
#                                                            |
#                                                    SingleAreaGrid
#
# Grid frequency is fed to the droop governor, which changes turbine opening.
# A 10% grid-load step is applied at t = 5 s.

const SBASE = 10.0e6
const PLOAD0 = 0.80
const PLOAD1 = 0.88
const STEP_TIME = 5.0
const XLINE = 0.60
const DELTA0 = asin(PLOAD0 * XLINE)

@named reservoir = ConstantLevelReservoir(
    h = 60.0,
    z = 0.0,
)

@named headrace = HydroPipe(
    H = 0.0,
    L = 800.0,
    D_i = 2.5,
    D_o = 2.5,
    Vdot0 = 5.0,
)

@named surge = SurgeTank(
    H = 80.0,
    L = 80.0,
    diameter = 6.0,
    h0 = 59.5,
    Vdot0 = 0.0,
)

@named penstock = HydroPipe(
    H = 120.0,
    L = 700.0,
    D_i = 2.0,
    D_o = 2.0,
    Vdot0 = 5.0,
)

@named turbine = HydroTurbineShaft(
    eta_h = 0.90,
    C_v = 0.00472,
    opening = 0.80,
    use_opening_input = true,
)

@named tail = PressureBoundary(p = 101325.0)

@named generator = ClassicalSynchronousGenerator(
    Sbase = SBASE,
    H = 4.0,
    damping = 0.5,
    f_grid = 50.0,
    poles = 12,
    V0 = 1.0,
    delta0 = DELTA0,
)

@named line = LosslessLine(X = XLINE)

@named grid = SingleAreaGrid(
    H = 8.0,
    damping = 1.0,
    f_ref = 50.0,
    V = 1.0,
    Pload0 = PLOAD0,
    use_load_input = true,
)

@named governor = DroopGovernor(
    f_ref = 50.0,
    R = 0.04,
    u0 = 0.80,
    T_g = 0.30,
    u_min = 0.10,
    u_max = 1.00,
)

eqs = [
    connect(reservoir.o, headrace.i),
    connect(headrace.o, surge.i),
    connect(surge.o, penstock.i),
    connect(penstock.o, turbine.i),
    connect(turbine.o, tail.i),

    connect(turbine.shaft, generator.mech),
    connect(generator.terminal, line.a),
    connect(line.b, grid.terminal),

    governor.f_meas ~ grid.f,
    turbine.u ~ governor.u,
    grid.P_load ~ ifelse(t < STEP_TIME, PLOAD0, PLOAD1),
]

@named plant = ODESystem(
    eqs,
    t;
    systems = [
        reservoir,
        headrace,
        surge,
        penstock,
        turbine,
        tail,
        generator,
        line,
        grid,
        governor,
    ],
)

sys = mtkcompile(plant)
prob = ODEProblem(sys, [], (0.0, 60.0))
sol = solve(
    prob,
    Rodas5P();
    tstops = [STEP_TIME],
    abstol = 1e-7,
    reltol = 1e-7,
)

println("Full component-wise nonlinear hydro FCR study")
println("retcode = ", sol.retcode)
println("grid f(0) [Hz] = ", sol[grid.f][1])
println("grid f_min [Hz] = ", minimum(sol[grid.f]))
println("grid f_final [Hz] = ", sol[grid.f][end])
println("generator f_final [Hz] = ", sol[generator.f][end])
println("turbine P_final [MW] = ", sol[turbine.P_t][end] / 1e6)
println("guide vane final [pu] = ", sol[governor.u][end])
println("surge h_final [m] = ", sol[surge.h][end])
println("headrace Q_final [m^3/s] = ", sol[headrace.Vdot][end])
println("penstock Q_final [m^3/s] = ", sol[penstock.Vdot][end])
println("line P_final [pu] = ", sol[line.P_ab][end])

SciMLBase.successful_retcode(sol.retcode) || error("Full component FCR simulation failed")
