using OpenHPLjl
using ModelingToolkit
using OrdinaryDiffEq
using SciMLBase

# First end-to-end OpenHPLjl validation topology:
#
#     Reservoir  -->  Pipe  -->  fixed-pressure tail boundary
#
# The reservoir supplies hydrostatic pressure. The pipe accelerates the water
# mass according to the OpenHPL momentum equation and Darcy friction.

@named reservoir = Reservoir(
    h0 = 50.0,
    z0 = 0.0,
    L = 500.0,
    W = 100.0,
)

@named pipe = Pipe(
    H = 0.0,
    L = 1000.0,
    D_i = 2.0,
    D_o = 2.0,
    p_eps = 1.5e-5,
    Vdot0 = 0.0,
)

@named tail = PressureBoundary(
    p = 101325.0,
    z = 0.0,
)

connections = [
    connect(reservoir.o, pipe.i),
    connect(pipe.o, tail.i),
]

@named hydraulic_system = ODESystem(
    connections,
    t;
    systems = [reservoir, pipe, tail],
)

sys = structural_simplify(hydraulic_system)
prob = ODEProblem(sys, [], (0.0, 60.0))
sol = solve(prob, Rodas5P(); abstol = 1e-8, reltol = 1e-8)

println("OpenHPLjl Reservoir-Pipe example")
println("retcode = ", sol.retcode)
println("t_final = ", sol.t[end])
println("Q_final = ", sol[pipe.Vdot][end], " m^3/s")
println("h_final = ", sol[reservoir.h][end], " m")

SciMLBase.successful_retcode(sol.retcode) || error("Hydraulic simulation failed")
