using OpenHPLjl
using ModelingToolkit
using OrdinaryDiffEq
using SciMLBase
using LinearAlgebra

println("FCR Study 01 — full component initialization")

Q0 = 55.0
h_surge0 = 117.63163567224585
opening0 = 0.5541282862699871
delta0 = 0.5208343152234535
m_surge0 = 1000.0 * (pi * 6.0^2 / 4.0) * h_surge0
dp_turbine0 = 2.01052121e6

println("equilibrium_Q_m3s = ", Q0)
println("equilibrium_surge_h_m = ", h_surge0)
println("equilibrium_opening = ", opening0)
println("equilibrium_delta_rad = ", delta0)
println("equilibrium_surge_mass_kg = ", m_surge0)
println("equilibrium_turbine_dp_Pa = ", dp_turbine0)

@named reservoir = ConstantLevelReservoir(h = 120.0)
@named headrace = HydroPipe(H = 0.0, L = 1200.0, D_i = 4.0, D_o = 4.0, Vdot0 = Q0)
@named surge = SurgeTank(H = 90.0, L = 90.0, diameter = 6.0, h0 = h_surge0, Vdot0 = 0.0)
@named penstock = HydroPipe(H = 90.0, L = 700.0, D_i = 3.5, D_o = 3.5, Vdot0 = Q0)
@named turbine = HydroTurbineShaft(C_v = 0.07, opening = opening0, eta_h = 0.90)
@named tail = PressureBoundary(p = 101325.0)
@named shaft = RigidShaft()
@named generator = ClassicalSynchronousGenerator(
    Sbase = 100e6,
    H = 4.0,
    damping = 1.0,
    f_grid = 50.0,
    poles = 12,
    delta0 = delta0,
)
@named line = LosslessLine(X = 0.50, Va = 1.0, Vb = 1.0)
@named grid = InfiniteBus(theta = 0.0)

eqs = [
    connect_hydraulic(reservoir.o, headrace.i),
    connect_hydraulic(headrace.o, surge.i),
    connect_hydraulic(surge.o, penstock.i),
    connect_hydraulic(penstock.o, turbine.i),
    connect_hydraulic(turbine.o, tail.i),
    connect_rotational(turbine.shaft, shaft.a),
    connect_rotational(shaft.b, generator.mech),
    connect_electrical(generator.terminal, line.a),
    connect_electrical(line.b, grid.terminal),
]

@named plant = ODESystem(
    eqs,
    t;
    systems = [reservoir, headrace, surge, penstock, turbine, tail,
               shaft, generator, line, grid],
)

println("Compiling ModelingToolkit system …")
sys = mtkcompile(plant)
compiled_unknowns = unknowns(sys)
println("Compiled: ", length(compiled_unknowns), " unknowns, ", length(equations(sys)), " equations")
println("compiled_unknowns = ", compiled_unknowns)
println("compiled_equations = ", equations(sys))

prob = ODEProblem(
    sys,
    [],
    (0.0, 20.0);
    guesses = [
        surge.m => m_surge0,
        turbine.dp => dp_turbine0,
    ],
)

println("u0 = ", prob.u0)

mass_matrix = prob.f.mass_matrix
println("mass_matrix = ", mass_matrix)
if mass_matrix isa AbstractMatrix
    println("mass_matrix_rank = ", rank(Matrix(mass_matrix)))
    println("mass_matrix_size = ", size(mass_matrix))
end

du0 = try
    collect(prob.f(prob.u0, prob.p, 0.0))
catch err
    if err isa MethodError
        buf = similar(prob.u0)
        prob.f(buf, prob.u0, prob.p, 0.0)
        collect(buf)
    else
        rethrow()
    end
end
println("du0 = ", du0)
for (state, value, derivative) in zip(compiled_unknowns, prob.u0, du0)
    println("INITIAL_STATE ", state, " = ", value, " ; derivative = ", derivative)
end
println("max_abs_du0 = ", maximum(abs, du0))

function try_solver(label, alg)
    println("SOLVER_TEST_BEGIN = ", label)
    pshort = remake(prob; tspan = (0.0, 0.2))
    try
        s = solve(pshort, alg; abstol = 1e-7, reltol = 1e-7, saveat = 0.01, maxiters = 1_000_000)
        println("SOLVER_TEST_RET = ", label, " => ", s.retcode)
        println("SOLVER_TEST_SAMPLES = ", label, " => ", length(s.t))
        println("SOLVER_TEST_TEND = ", label, " => ", last(s.t))
        println("SOLVER_TEST_FEND = ", label, " => ", last(s[generator.f]))
        println("SOLVER_TEST_QEND = ", label, " => ", last(s[penstock.Vdot]))
        println("SOLVER_TEST_HEND = ", label, " => ", last(s[surge.h]))
        return s
    catch err
        println("SOLVER_TEST_ERROR = ", label, " => ", typeof(err), ": ", sprint(showerror, err))
        return nothing
    end
end

sol_rodas = try_solver("Rodas5P", Rodas5P())
sol_fbdf = try_solver("FBDF", FBDF())
sol_rosen = try_solver("Rosenbrock23", Rosenbrock23())

successful = [s for s in (sol_rodas, sol_fbdf, sol_rosen) if s !== nothing && SciMLBase.successful_retcode(s.retcode)]
println("successful_solver_count = ", length(successful))
println("STUDY01_OK = ", !isempty(successful))
!isempty(successful) || error("Study 01 solver comparison found no successful integrator")
