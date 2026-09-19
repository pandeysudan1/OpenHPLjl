using Test
using OpenHPLjl
using ModelingToolkit
using OrdinaryDiffEq
using ModelingToolkit: t_nounits as t, D_nounits as D

println("Julia version: ", VERSION)
println("ModelingToolkit version: ", Base.pkgversion(ModelingToolkit))
println("OrdinaryDiffEq version: ", Base.pkgversion(OrdinaryDiffEq))

@testset "OpenHPLjl package smoke test" begin
    @test occursin("ModelingToolkit", project_status())

    @parameters τ = 3.0
    @variables x(t) = 0.0
    eqs = [D(x) ~ (1 - x) / τ]
    @named smoke_model = System(eqs, t)

    compile_seconds = @elapsed compiled = mtkcompile(smoke_model)
    println("MTK compile seconds: ", round(compile_seconds; digits = 3))

    prob = ODEProblem(compiled, [], (0.0, 1.0))
    solve_seconds = @elapsed sol = solve(prob, Tsit5(); abstol = 1e-10, reltol = 1e-10)
    println("ODE solve seconds: ", round(solve_seconds; digits = 3))

    expected = 1 - exp(-1 / 3)
    @test isapprox(sol.u[end][1], expected; atol = 1e-7, rtol = 1e-7)
end
