using OpenHPLjl
using ModelingToolkit
using OrdinaryDiffEq

# reservoir -> headrace -> surge tank -> penstock -> tail boundary

@named reservoir = Reservoir(h0 = 80.0, z0 = 0.0)
@named headrace = HydroPipe(H = 0.0, L = 1500.0, D_i = 3.5, D_o = 3.5, Vdot0 = 8.0)
@named surge = SurgeTank(H = 80.0, L = 80.0, diameter = 5.0, h0 = 45.0, Vdot0 = 0.0)
@named penstock = HydroPipe(H = 80.0, L = 700.0, D_i = 2.5, D_o = 2.5, Vdot0 = 8.0)
@named tail = PressureBoundary(p = 101325.0)

connections = [
    connect(reservoir.o, headrace.i),
    connect(headrace.o, surge.i),
    connect(surge.o, penstock.i),
    connect(penstock.o, tail.i),
]

@named plant = ODESystem(
    connections,
    t;
    systems = [reservoir, headrace, surge, penstock, tail],
)

sys = mtkcompile(plant)
prob = ODEProblem(sys, [], (0.0, 120.0))
sol = solve(prob, Rodas5P(); abstol = 1e-8, reltol = 1e-8)

println("OpenHPLjl surge-tank example")
println("retcode = ", sol.retcode)
println("final time = ", sol.t[end])
