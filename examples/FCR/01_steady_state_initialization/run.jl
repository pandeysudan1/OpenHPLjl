using OpenHPLjl
using ModelingToolkit
using NonlinearSolve
using OrdinaryDiffEq
using SciMLBase
using LinearAlgebra

println("FCR Study 01 — HomotopyProblem initialization")

# -----------------------------------------------------------------------------
# 1. Nonlinear hydro-electrical operating point solved by homotopy continuation
# -----------------------------------------------------------------------------
Q_target = 55.0
rho = 1000.0
g = 9.81
mu = 1.0e-3
p_eps = 1.5e-5

h_res = 120.0
L_hr = 1200.0
D_hr = 4.0
A_hr = pi * D_hr^2 / 4

H_pen = 90.0
L_pen = 700.0
D_pen = 3.5
A_pen = pi * D_pen^2 / 4

C_v = 0.07
eta_h = 0.90
Sbase = 100e6
X_line = 0.50

# Deliberately rough λ=0 seeds. The actual operating point is not hard-coded.
h_seed = 105.0
dp_seed = 1.70e6
u_seed = 0.65
delta_seed = 0.40
u0_hom = [Q_target, h_seed, dp_seed, u_seed, delta_seed]

# SciML HomotopyProblem uses f(u, p, λ) = 0. At λ=0 the residual is the
# simple seed system; at λ=1 it is the full nonlinear operating-point system.
function operating_point_residual(u, p, λ)
    q, h, dp, opening, delta = u

    v_hr = q / A_hr
    v_pen = q / A_pen
    F_hr = darcy_friction(v_hr, D_hr, L_hr, rho, mu, p_eps)
    F_pen = darcy_friction(v_pen, D_pen, L_pen, rho, mu, p_eps)

    actual = [
        (q - Q_target) / Q_target,
        ((rho * g * (h_res - h)) * A_hr - F_hr) /
            (rho * g * h_res * A_hr),
        ((rho * g * (h + H_pen) - dp) * A_pen - F_pen) /
            (rho * g * (h_seed + H_pen) * A_pen),
        (dp * (C_v * opening)^2 - q * abs(q)) / Q_target^2,
        eta_h * dp * q / Sbase - (1 / X_line) * sin(delta),
    ]

    simple = [
        (q - Q_target) / Q_target,
        (h - h_seed) / h_res,
        (dp - dp_seed) / dp_seed,
        opening - u_seed,
        delta - delta_seed,
    ]

    return (1 - λ) .* simple .+ λ .* actual
end

op_prob = HomotopyProblem(operating_point_residual, u0_hom; λspan = (0.0, 1.0))
println("homotopy_problem_type = ", typeof(op_prob))
op_alg = HomotopySweep(inner = NewtonRaphson(), nsteps = 30, adaptive = false)
op_sol = solve(op_prob, op_alg; abstol = 1e-10, reltol = 1e-10, maxiters = 200)
println("homotopy_retcode = ", op_sol.retcode)
println("homotopy_u = ", op_sol.u)
println("homotopy_resid_field = ", op_sol.resid)

target_residual = operating_point_residual(op_sol.u, nothing, 1.0)
target_max_residual = maximum(abs, target_residual)
println("homotopy_target_residual = ", target_residual)
println("homotopy_max_residual = ", target_max_residual)

# Some current NonlinearSolve/SciMLBase combinations can leave the continuation
# solution retcode at Default. The physical acceptance criterion is therefore
# the target λ=1 residual, while still reporting the library retcode above.
homotopy_ok = all(isfinite, op_sol.u) && target_max_residual < 1e-8
println("HOMOTOPY_OK = ", homotopy_ok)
homotopy_ok || error("Homotopy operating-point solve failed target-residual check")

Q0, h_surge0, dp_turbine0, opening0, delta0 = op_sol.u
m_surge0 = rho * (pi * 6.0^2 / 4.0) * h_surge0

println("homotopy_Q_m3s = ", Q0)
println("homotopy_surge_h_m = ", h_surge0)
println("homotopy_turbine_dp_Pa = ", dp_turbine0)
println("homotopy_opening = ", opening0)
println("homotopy_delta_rad = ", delta0)

# -----------------------------------------------------------------------------
# 2. Full nonlinear acausal hydro -> shaft -> generator -> infinite bus model
# -----------------------------------------------------------------------------
@named reservoir = ConstantLevelReservoir(h = h_res)
@named headrace = HydroPipe(H = 0.0, L = L_hr, D_i = D_hr, D_o = D_hr, Vdot0 = Q0)
@named surge = SurgeTank(H = 90.0, L = 90.0, diameter = 6.0, h0 = h_surge0, Vdot0 = 0.0)
@named penstock = HydroPipe(H = H_pen, L = L_pen, D_i = D_pen, D_o = D_pen, Vdot0 = Q0)
@named turbine = HydroTurbineShaft(C_v = C_v, opening = opening0, eta_h = eta_h)
@named tail = PressureBoundary(p = 101325.0)
@named shaft = RigidShaft()
@named generator = ClassicalSynchronousGenerator(
    Sbase = Sbase,
    H = 4.0,
    damping = 1.0,
    f_grid = 50.0,
    poles = 12,
    delta0 = delta0,
)
@named line = LosslessLine(X = X_line, Va = 1.0, Vb = 1.0)
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

@named plant = System(
    eqs,
    t;
    systems = [reservoir, headrace, surge, penstock, turbine, tail,
               shaft, generator, line, grid],
)

println("Compiling full ModelingToolkit system …")
sys = mtkcompile(plant)
compiled_unknowns = unknowns(sys)
println("Compiled: ", length(compiled_unknowns), " unknowns, ", length(equations(sys)), " equations")

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
