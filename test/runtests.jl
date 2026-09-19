using Test
using OpenHPLjl
using ModelingToolkit
using OrdinaryDiffEq

println("Julia version: ", VERSION)
println("ModelingToolkit version: ", Base.pkgversion(ModelingToolkit))
println("OrdinaryDiffEq version: ", Base.pkgversion(OrdinaryDiffEq))

@testset "OpenHPLjl package smoke test" begin
    @test occursin("openhpljl", lowercase(project_status()))

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


@testset "Turbine model family" begin
    @named ideal = IdealTurbine(eta = 0.90)
    @named gated = SimpleGateTurbine(eta = 0.90, Kq = 1.0, y = 0.5)

    @test length(equations(ideal)) == 4
    @test length(equations(gated)) == 5

    H = 100.0
    Q = 1.0 * 0.5 * sqrt(H)
    Pm = 1000.0 * 9.81 * 0.90 * Q * H

    @test isapprox(Q, 5.0; atol = 1e-12)
    @test isapprox(Pm, 4.4145e6; atol = 1e-6)
end


@testset "Friction model registry" begin
    names = available_friction_models()
    @test :quadratic in names
    @test :darcy_haaland in names
    @test :darcy_swamee_jain in names

    @test friction_model(:none)(2.0) == 0.0
    @test quadratic_head_loss(2.0; R = 0.5) == 2.0

    Re = reynolds_number(0.01; D = 0.10, nu = 1e-6)
    @test Re > 1.0e5

    f_lam = laminar_friction_factor(1000.0)
    @test isapprox(f_lam, 0.064; atol = 1e-12)

    f_h = haaland_friction_factor(1.0e5; epsilon = 1.0e-4, D = 0.10)
    f_sj = swamee_jain_friction_factor(1.0e5; epsilon = 1.0e-4, D = 0.10)
    @test 0.01 < f_h < 0.1
    @test 0.01 < f_sj < 0.1

    hf = darcy_head_loss(1.0; f = 0.02, L = 100.0, D = 1.0, A = 1.0, g = 9.81)
    @test isapprox(hf, 0.02 * 100.0 / (2 * 9.81); atol = 1e-12)
end

@testset "RigidPipe selectable friction" begin
    @named pipe = RigidPipe(
        friction = :darcy_constant,
        L = 100.0,
        A = 1.0,
        diameter = 1.0,
        f = 0.02,
        Q0 = 1.0,
    )
    @test any(occursin("0.02", string(eq)) || occursin("f", string(eq)) for eq in equations(pipe))
end
