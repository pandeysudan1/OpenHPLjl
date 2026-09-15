using OpenHPLjl
using ModelingToolkit
using OrdinaryDiffEq
using SciMLBase

# OpenHPL-style transient-droop governor on the same nonlinear hydro chain used
# by fcr_load_step.jl. Electrical load increases by 10% at t = 5 s.

const P0 = 15.0e6
const STEP_TIME = 5.0
const STEP_FRACTION = 0.10

@named reservoir = Reservoir(h0 = 60.0, z0 = 0.0, L = 300.0, W = 80.0)
@named headrace = HydroPipe(H = 0.0, L = 800.0, D_i = 2.5, D_o = 2.5, Vdot0 = 2.0)
@named surge = SurgeTank(H = 80.0, L = 80.0, diameter = 6.0, h0 = 40.0, Vdot0 = 0.0)
@named penstock = HydroPipe(H = 120.0, L = 700.0, D_i = 2.0, D_o = 2.0, Vdot0 = 2.0)
@named turbine = Turbine(
    eta_h = 0.90,
    C_v = 0.012,
    opening = 0.8,
    use_opening_input = true,
)
@named tail = PressureBoundary(p = 101325.0)
@named gen = SimpleGenerator(
    J = 2.0e5,
    poles = 12,
    f_grid = 50.0,
    Pload = P0,
    use_load_input = true,
)
@named governor = OpenHPLGovernor(
    f_ref = 50.0,
    Y_ref = 0.8,
    T_p = 0.04,
    T_g = 0.2,
    T_r = 1.75,
    droop = 0.10,
    delta = 0.04,
    rate_open = 0.05,
    rate_close = 0.20,
)

eqs = [
    connect(reservoir.o, headrace.i),
    connect(headrace.o, surge.i),
    connect(surge.o, penstock.i),
    connect(penstock.o, turbine.i),
    connect(turbine.o, tail.i),
    gen.P_m ~ turbine.P_t,
    governor.f_meas ~ gen.f,
    turbine.u ~ governor.Y,
    gen.P_load ~ ifelse(t < STEP_TIME, P0, P0 * (1 + STEP_FRACTION)),
]

@named unit = ODESystem(
    eqs,
    t;
    systems = [reservoir, headrace, surge, penstock, turbine, tail, gen, governor],
)

sys = mtkcompile(unit)
prob = ODEProblem(sys, [], (0.0, 30.0))
sol = solve(
    prob,
    Rodas5P();
    tstops = [STEP_TIME],
    abstol = 1e-7,
    reltol = 1e-7,
)

println("OpenHPLjl transient-droop FCR example")
println("retcode = ", sol.retcode)
println("f(0) [Hz] = ", sol[gen.f][1])
println("f_final [Hz] = ", sol[gen.f][end])
println("Y_final [pu] = ", sol[governor.Y][end])
println("P_t_final [MW] = ", sol[turbine.P_t][end] / 1e6)
println("surge h_final [m] = ", sol[surge.h][end])

SciMLBase.successful_retcode(sol.retcode) || error("Transient-droop FCR simulation failed")
