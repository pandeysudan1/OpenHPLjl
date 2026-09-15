using OpenHPLjl
using ModelingToolkit
using OrdinaryDiffEq
using SciMLBase

println("FCR Study 01 — full component initialization")

# Canonical nonlinear hydro-to-grid equilibrium.
# Keep the original 55 m^3/s waterway target, but make the hydraulic,
# mechanical and electrical operating points mutually consistent.
Q0 = 55.0
h_surge0 = 117.63163567224585
opening0 = 0.5541282862699871
delta0 = 0.5208343152234535

println("equilibrium_Q_m3s = ", Q0)
println("equilibrium_surge_h_m = ", h_surge0)
println("equilibrium_opening = ", opening0)
println("equilibrium_delta_rad = ", delta0)

@named reservoir = ConstantLevelReservoir(h = 120.0)
@named headrace = HydroPipe(H = 0.0, L = 1200.0, D_i = 4.0, D_o = 4.0, Vdot0 = Q0)
@named surge = SurgeTank(H = 90.0, L = 90.0, diameter = 6.0, h0 = h_surge0, Vdot0 = 0.0)
@named penstock = HydroPipe(H = 90.0, L = 700.0, D_i = 3.5, D_o = 3.5, Vdot0 = Q0)
@named turbine = HydroTurbineShaft(C_v = 0.07, opening = opening0, eta_h = 0.90)
@named tail = PressureBoundary(p = 101325.0)
@named shaft = RigidShaft()
@named generator = ClassicalSynchronousGenerator(
    Sbase = 100e6,
    H = 4.0,
    damping = 1.0,
    f_grid = 50.0,
    poles = 12,
    V0 = 1.0,
    delta0 = delta0,
)
@named line = LosslessLine(X = 0.50)
@named grid = InfiniteBus(V = 1.0, theta = 0.0)

eqs = [
    connect_hydraulic(reservoir.o, headrace.i),
    connect_hydraulic(headrace.o, surge.i),
    connect_hydraulic(surge.o, penstock.i),
    connect_hydraulic(penstock.o, turbine.i),
    connect_hydraulic(turbine.o, tail.i),
    connect_rotational(turbine.shaft, shaft.a),
    connect_rotational(shaft.b, generator.mech),
    connect_electrical(generator.terminal, line.a),
    connect_electrical(line.b, grid.terminal),
]

@named plant = ODESystem(
    eqs,
    t;
    systems = [reservoir, headrace, surge, penstock, turbine, tail,
               shaft, generator, line, grid],
)

println("Compiling ModelingToolkit system …")
sys = mtkcompile(plant)
println("Compiled: ", length(unknowns(sys)), " unknowns, ", length(equations(sys)), " equations")

# A true steady equilibrium should remain stationary over this interval.
prob = ODEProblem(sys, [], (0.0, 20.0))
sol = solve(prob, Rodas5P(); abstol = 1e-7, reltol = 1e-7, saveat = 0.1)

println("retcode = ", sol.retcode)
println("samples = ", length(sol.t))
println("f_start_Hz = ", first(sol[generator.f]))
println("f_end_Hz = ", last(sol[generator.f]))
println("P_e_start_pu = ", first(sol[generator.P_e]))
println("P_e_end_pu = ", last(sol[generator.P_e]))
println("Q_penstock_start_m3s = ", first(sol[penstock.Vdot]))
println("Q_penstock_end_m3s = ", last(sol[penstock.Vdot]))
println("surge_h_start_m = ", first(sol[surge.h]))
println("surge_h_end_m = ", last(sol[surge.h]))
println("turbine_P_end_MW = ", last(sol[turbine.P_t]) / 1e6)

ok = SciMLBase.successful_retcode(sol.retcode) &&
     all(isfinite, sol[generator.f]) &&
     all(isfinite, sol[penstock.Vdot]) &&
     all(isfinite, sol[surge.h]) &&
     all(isfinite, sol[turbine.P_t])

println("STUDY01_OK = ", ok)
ok || error("Study 01 failed finite-state / solver checks")
