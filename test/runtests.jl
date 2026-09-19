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
