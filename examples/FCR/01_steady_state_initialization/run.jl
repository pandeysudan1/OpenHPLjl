using OpenHPLjl
using ModelingToolkit
using OrdinaryDiffEq
using SciMLBase
using LinearAlgebra

println("FCR Study 01 — physical operating-point continuation")

# -----------------------------------------------------------------------------
# 1. Physical nonlinear hydro-electrical continuation to the target flow
# -----------------------------------------------------------------------------
Q_start = 20.0
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

function physical_operating_point(q)
    q > 0 || error("Study 01 expects positive turbine flow")

    v_hr = q / A_hr
    F_hr = darcy_friction(v_hr, D_hr, L_hr, rho, mu, p_eps)
    h = h_res - F_hr / (rho * g * A_hr)

    v_pen = q / A_pen
    F_pen = darcy_friction(v_pen, D_pen, L_pen, rho, mu, p_eps)
    dp = rho * g * (h + H_pen) - F_pen / A_pen
    dp > 0 || error("Non-positive turbine pressure drop at q=$q")

    opening = sqrt(q * abs(q) / dp) / C_v
    sin_delta = X_line * eta_h * dp * q / Sbase
    abs(sin_delta) <= 1 || error("No stable small-angle electrical equilibrium at q=$q; sin(delta)=$sin_delta")
    delta = asin(sin_delta)

    return [q, h, dp, opening, delta]
end

function physical_residual(u, q_command)
    q, h, dp, opening, delta = u
    v_hr = q / A_hr
    v_pen = q / A_pen
    F_hr = darcy_friction(v_hr, D_hr, L_hr, rho, mu, p_eps)
    F_pen = darcy_friction(v_pen, D_pen, L_pen, rho, mu, p_eps)

    return [
        (q - q_command) / Q_target,
        ((rho * g * (h_res - h)) * A_hr - F_hr) / (rho * g * h_res * A_hr),
        ((rho * g * (h + H_pen) - dp) * A_pen - F_pen) / (rho * g * (h_res + H_pen) * A_pen),
        (dp * (C_v * opening)^2 - q * abs(q)) / Q_target^2,
        eta_h * dp * q / Sbase - (1 / X_line) * sin(delta),
    ]
end

op = nothing
for i in 0:30
    λ = i / 30
    qλ = Q_start + λ * (Q_target - Q_start)
    global op = physical_operating_point(qλ)
    r = physical_residual(op, qλ)
    maxres = norm(r, Inf)
    println("FLOW_CONTINUATION_STEP λ=", round(λ; digits=4),
            " Q_m3s=", op[1],
            " h_m=", op[2],
            " dp_Pa=", op[3],
            " opening=", op[4],
            " delta_rad=", op[5],
            " maxres=", maxres)
    maxres < 1e-10 || error("Physical continuation residual failed at λ=$λ")
end

op_residual = physical_residual(op, Q_target)
op_max_residual = norm(op_residual, Inf)
println("operating_point = ", op)
println("operating_point_residual = ", op_residual)
println("operating_point_max_residual = ", op_max_residual)
operating_point_ok = all(isfinite, op) && op_max_residual < 1e-10
println("OPERATING_POINT_OK = ", operating_point_ok)
operating_point_ok || error("Physical operating-point continuation failed")

Q0, h_surge0, dp_turbine0, opening0, delta0 = op
m_surge0 = rho * (pi * 6.0^2 / 4.0) * h_surge0

println("Q0_m3s = ", Q0)
println("surge_h0_m = ", h_surge0)
println("turbine_dp0_Pa = ", dp_turbine0)
println("opening0 = ", opening0)
println("delta0_rad = ", delta0)

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
