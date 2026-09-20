using OpenHPLjl
using ModelingToolkit
using OrdinaryDiffEq

# Complete nonlinear equation-based hydropower plant:
# reservoir -> waterways -> surge tank -> turbine -> shaft -> generator -> grid
#                                          ^                        |
#                                          |                        v
#                                          +-- governor <- frequency sensor

@named plant = ReducedSMIB()

println("Hierarchical systems before compilation: ", length(ModelingToolkit.get_systems(plant)))
println("Equations before compilation: ", length(equations(plant)))

compiled = mtkcompile(plant)
println("Unknowns after compilation: ", length(unknowns(compiled)))
println("Equations after compilation: ", length(equations(compiled)))

prob = ODEProblem(compiled, [], (0.0, 5.0))
sol = solve(prob, Rodas5P(); abstol = 1e-8, reltol = 1e-8)

println("retcode = ", sol.retcode)
println("final shaft frequency [Hz] = ", sol[compiled.frequency_sensor.f][end])
println("final turbine flow [m^3/s] = ", sol[compiled.turbine.Q][end])
println("final turbine power [MW] = ", sol[compiled.turbine.Ph][end] / 1e6)
println("final generator power [MW] = ", sol[compiled.generator.Pe][end] / 1e6)
println("final surge head [m] = ", sol[compiled.surge.H][end])
println("final guide-vane opening [-] = ", sol[compiled.governor.y][end])
