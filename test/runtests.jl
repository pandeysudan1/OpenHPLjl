using Test
using OpenHPLjl
using ModelingToolkit
using OrdinaryDiffEq
using SciMLBase

@testset "OpenHPLjl hydraulic smoke test" begin
    @named reservoir = Reservoir(h0 = 20.0, z0 = 0.0, L = 200.0, W = 50.0)
    @named pipe = Pipe(H = 0.0, L = 500.0, D_i = 1.5, D_o = 1.5, Vdot0 = 0.0)
    @named tail = PressureBoundary(p = 101325.0, z = 0.0)

    eqs = [
        connect(reservoir.o, pipe.i),
        connect(pipe.o, tail.i),
    ]

    @named model = ODESystem(eqs, t; systems = [reservoir, pipe, tail])
    sys = structural_simplify(model)
    prob = ODEProblem(sys, [], (0.0, 5.0))
    sol = solve(prob, Rodas5P(); abstol = 1e-7, reltol = 1e-7)

    @test SciMLBase.successful_retcode(sol.retcode)
    @test all(isfinite, sol[pipe.Vdot])
    @test all(isfinite, sol[reservoir.h])
end
