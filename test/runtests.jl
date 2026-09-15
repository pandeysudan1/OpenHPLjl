using Test
using OpenHPLjl
using ModelingToolkit
using OrdinaryDiffEq
using SciMLBase

@testset "OpenHPLjl hydraulic smoke test" begin
    @named reservoir = Reservoir(h0 = 20.0, z0 = 0.0, L = 200.0, W = 50.0)
    @named pipe = HydroPipe(H = 0.0, L = 500.0, D_i = 1.5, D_o = 1.5, Vdot0 = 0.0)
    @named tail = PressureBoundary(p = 101325.0)

    eqs = [
        connect(reservoir.o, pipe.i),
        connect(pipe.o, tail.i),
    ]

    @named model = ODESystem(eqs, t; systems = [reservoir, pipe, tail])
    sys = mtkcompile(model)
    prob = ODEProblem(sys, [], (0.0, 5.0))
    sol = solve(prob, Rodas5P(); abstol = 1e-7, reltol = 1e-7)

    @test SciMLBase.successful_retcode(sol.retcode)
    @test all(isfinite, sol[pipe.Vdot])
    @test all(isfinite, sol[reservoir.h])
end

@testset "OpenHPLjl simple surge tank chain" begin
    @named reservoir = Reservoir(h0 = 80.0, z0 = 0.0)
    @named headrace = HydroPipe(H = 0.0, L = 1500.0, D_i = 3.5, D_o = 3.5, Vdot0 = 8.0)
    @named surge = SurgeTank(H = 80.0, L = 80.0, diameter = 5.0, h0 = 45.0, Vdot0 = 0.0)
    @named penstock = HydroPipe(H = 80.0, L = 700.0, D_i = 2.5, D_o = 2.5, Vdot0 = 8.0)
    @named tail = PressureBoundary(p = 101325.0)

    eqs = [
        connect(reservoir.o, headrace.i),
        connect(headrace.o, surge.i),
        connect(surge.o, penstock.i),
        connect(penstock.o, tail.i),
    ]

    @named model = ODESystem(
        eqs,
        t;
        systems = [reservoir, headrace, surge, penstock, tail],
    )

    sys = mtkcompile(model)
    prob = ODEProblem(sys, [], (0.0, 10.0))
    sol = solve(prob, Rodas5P(); abstol = 1e-7, reltol = 1e-7)

    @test SciMLBase.successful_retcode(sol.retcode)
    @test all(isfinite, sol[surge.h])
    @test all(x -> x >= 0.0, sol[surge.h])
    @test all(isfinite, sol[headrace.Vdot])
    @test all(isfinite, sol[penstock.Vdot])
end

@testset "OpenHPL transient-droop governor" begin
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
        governor.f_meas ~ ifelse(t < 1.0, 50.0, 49.8),
    ]

    @named model = ODESystem(eqs, t; systems = [governor])
    sys = mtkcompile(model)
    prob = ODEProblem(sys, [], (0.0, 4.0))
    sol = solve(prob, Rodas5P(); tstops = [1.0], abstol = 1e-8, reltol = 1e-8)

    @test SciMLBase.successful_retcode(sol.retcode)
    @test all(isfinite, sol[governor.Y])
    @test maximum(sol[governor.Y]) <= 1.0 + 1e-8
    @test minimum(sol[governor.Y]) >= -1e-8
    @test sol[governor.Y][end] > sol[governor.Y][1]
end
