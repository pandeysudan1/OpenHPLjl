using OpenHPLjl
using ModelingToolkit
using OrdinaryDiffEq

@named reservoir = Reservoir(h0 = 60.0, z0 = 0.0, L = 300.0, W = 80.0)
@named headrace = HydroPipe(H = 0.0, L = 800.0, D_i = 2.5, D_o = 2.5, Vdot0 = 2.0)
@named surge = SurgeTank(H = 80.0, L = 80.0, diameter = 6.0, h0 = 40.0, Vdot0 = 0.0)
@named penstock = HydroPipe(H = 120.0, L = 700.0, D_i = 2.0, D_o = 2.0, Vdot0 = 2.0)
@named turbine = Turbine(eta_h = 0.90, C_v = 0.012, opening = 0.8)
@named tail = PressureBoundary(p = 101325.0)
@named gen = SimpleGenerator(J = 2.0e5, poles = 12, f_grid = 50.0, Pload = 15.0e6)

eqs = [
    connect(reservoir.o, headrace.i),
    connect(headrace.o, surge.i),
    connect(surge.o, penstock.i),
    connect(penstock.o, turbine.i),
    connect(turbine.o, tail.i),
    gen.P_m ~ turbine.P_t,
]

@named unit = ODESystem(eqs, t; systems = [reservoir, headrace, surge, penstock, turbine, tail, gen])
sys = mtkcompile(unit)
prob = ODEProblem(sys, [], (0.0, 30.0))
sol = solve(prob, Rodas5P(); abstol = 1e-7, reltol = 1e-7)

println("retcode = ", sol.retcode)
println("final frequency [Hz] = ", sol[gen.f][end])
println("final turbine power [MW] = ", sol[turbine.P_t][end] / 1e6)
println("final surge level [m] = ", sol[surge.h][end])
