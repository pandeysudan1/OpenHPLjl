using OpenHPLjl
using ModelingToolkit
using OrdinaryDiffEq

@named reservoir = Reservoir(h0 = 60.0, z0 = 0.0, L = 300.0, W = 80.0)
@named headrace = Pipe(H = 0.0, L = 800.0, D_i = 2.5, D_o = 2.5, Vdot0 = 2.0)
@named surge = SurgeTank(H = 80.0, L = 80.0, D = 6.0, h0 = 40.0, Vdot0 = 0.0)
@named penstock = Pipe(H = 120.0, L = 700.0, D_i = 2.0, D_o = 2.0, Vdot0 = 2.0)
@named turbine = Turbine(eta_h = 0.90, C_v = 0.012, opening = 0.8)
@named tail = PressureBoundary(p = 101325.0, z = -120.0)

eqs = [
    connect(reservoir.o, headrace.i),
    connect(headrace.o, surge.i),
    connect(surge.o, penstock.i),
    connect(penstock.o, turbine.i),
    connect(turbine.o, tail.i),
]

@named plant = ODESystem(eqs, t; systems = [reservoir, headrace, surge, penstock, turbine, tail])
sys = structural_simplify(plant)
prob = ODEProblem(sys, [], (0.0, 60.0))
sol = solve(prob, Rodas5P(); abstol = 1e-7, reltol = 1e-7)

println("retcode = ", sol.retcode)
println("final turbine flow [m^3/s] = ", sol[turbine.Vdot][end])
println("final turbine power [W] = ", sol[turbine.P_t][end])
println("final surge level [m] = ", sol[surge.h][end])
