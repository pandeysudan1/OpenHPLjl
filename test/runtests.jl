using Test
using OpenHPLjl
using ModelingToolkit
using OrdinaryDiffEq

println("Julia version: ", VERSION)
println("ModelingToolkit version: ", Base.pkgversion(ModelingToolkit))
println("OrdinaryDiffEq version: ", Base.pkgversion(OrdinaryDiffEq))

@testset "OpenHPLjl package smoke test" begin
    @test occursin("reservoir", lowercase(project_status()))

    @named port = HydraulicPort()
    @test length(unknowns(port)) == 2
end

@testset "InfiniteReservoir" begin
    @named reservoir = InfiniteReservoir(H0 = 125.0)
    sys = mtkcompile(reservoir)

    @test isempty(unknowns(sys)) || all(!isequal(reservoir.port.H), unknowns(sys))
end

@testset "Dynamic Reservoir mass balance" begin
    @named reservoir = Reservoir(A = 1000.0, H0 = 100.0, Qin = 10.0)

    # Port flow is positive into a component. An outflow of 12 m^3/s is -12.
    boundary_eqs = [
        reservoir.port.Q ~ -12.0
    ]

    @named model = System(boundary_eqs, ModelingToolkit.t_nounits; systems = [reservoir])

    compile_seconds = @elapsed compiled = mtkcompile(model)
    println("Reservoir MTK compile seconds: ", round(compile_seconds; digits = 3))

    prob = ODEProblem(compiled, [], (0.0, 10.0))
    solve_seconds = @elapsed sol = solve(
        prob,
        Tsit5();
        abstol = 1e-10,
        reltol = 1e-10,
    )
    println("Reservoir solve seconds: ", round(solve_seconds; digits = 3))

    expected_H10 = 100.0 + ((10.0 - 12.0) / 1000.0) * 10.0
    simulated_H10 = sol[compiled.reservoir.H][end]

    @test isapprox(simulated_H10, expected_H10; atol = 1e-8, rtol = 1e-8)
    @test isapprox(expected_H10, 99.98; atol = 1e-12)
end


@testset "RigidPipe momentum balance" begin
    @named pipe = RigidPipe(L = 100.0, A = 1.0, g = 9.81, R = 0.0, Q0 = 0.0)

    boundary_eqs = [
        pipe.inlet.H ~ 100.0
        pipe.outlet.H ~ 90.0
    ]

    @named model = System(boundary_eqs, ModelingToolkit.t_nounits; systems = [pipe])
    compiled = mtkcompile(model)

    prob = ODEProblem(compiled, [], (0.0, 1.0))
    sol = solve(prob, Tsit5(); abstol = 1e-10, reltol = 1e-10)

    expected_Q1 = (9.81 * 1.0 / 100.0) * (100.0 - 90.0) * 1.0
    simulated_Q1 = sol[compiled.pipe.Q][end]

    @test isapprox(expected_Q1, 0.981; atol = 1e-12)
    @test isapprox(simulated_Q1, expected_Q1; atol = 1e-8, rtol = 1e-8)
end


@testset "SurgeTank mass balance" begin
    @named tank = SurgeTank(As = 100.0, H0 = 50.0)

    boundary_eqs = [
        tank.inlet.Q ~ 5.0
        tank.outlet.Q ~ -3.0
    ]

    @named model = System(boundary_eqs, ModelingToolkit.t_nounits; systems = [tank])
    compiled = mtkcompile(model)

    prob = ODEProblem(compiled, [], (0.0, 10.0))
    sol = solve(prob, Tsit5(); abstol = 1e-10, reltol = 1e-10)

    expected_H10 = 50.0 + ((5.0 - 3.0) / 100.0) * 10.0
    simulated_H10 = sol[compiled.tank.H][end]

    @test isapprox(expected_H10, 50.2; atol = 1e-12)
    @test isapprox(simulated_H10, expected_H10; atol = 1e-8, rtol = 1e-8)
end
