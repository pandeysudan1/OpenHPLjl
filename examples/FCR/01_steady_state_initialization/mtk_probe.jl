using OpenHPLjl
using ModelingToolkit
using SciMLBase
using LinearAlgebra

println("FCR Study 01 — MTK full-plant compile probe")

Q0 = 55.0
h_surge0 = 117.63163567224585
dp_turbine0 = 2.0105212104158616e6
opening0 = 0.554128286269987
delta0 = 0.5208343152234537

h_res = 120.0
L_hr = 1200.0
D_hr = 4.0
H_pen = 90.0
L_pen = 700.0
D_pen = 3.5
C_v = 0.07
eta_h = 0.90
Sbase = 100e6
X_line = 0.50
rho = 1000.0
m_surge0 = rho * (pi * 6.0^2 / 4.0) * h_surge0

println("PROBE_OPERATING_POINT Q=", Q0,
        " h=", h_surge0,
        " dp=", dp_turbine0,
        " opening=", opening0,
        " delta=", delta0)

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

println("PROBE_COMPONENTS_OK")

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
println("PROBE_CONNECTORS_OK count=", length(eqs))

@named plant = System(
    eqs,
    t;
    systems = [reservoir, headrace, surge, penstock, turbine, tail,
               shaft, generator, line, grid],
)
println("PROBE_SYSTEM_OK unknowns_before=", length(unknowns(plant)),
        " equations_before=", length(equations(plant)))

println("PROBE_MTKCOMPILE_BEGIN")
sys = mtkcompile(plant)
println("PROBE_MTKCOMPILE_OK unknowns=", length(unknowns(sys)),
        " equations=", length(equations(sys)))

println("PROBE_ODEPROBLEM_BEGIN")
prob = ODEProblem(
    sys,
    [],
    (0.0, 0.2);
    guesses = [
        surge.m => m_surge0,
        turbine.dp => dp_turbine0,
    ],
)
println("PROBE_ODEPROBLEM_OK nstates=", length(prob.u0))
println("PROBE_U0 = ", prob.u0)

mass_matrix = try
    prob.f.mass_matrix
catch
    nothing
end
println("PROBE_MASS_MATRIX_TYPE = ", typeof(mass_matrix))
if mass_matrix isa AbstractMatrix
    println("PROBE_MASS_MATRIX_SIZE = ", size(mass_matrix))
    println("PROBE_MASS_MATRIX_RANK = ", rank(Matrix(mass_matrix)))
end

println("MTK_PROBE_OK = true")
