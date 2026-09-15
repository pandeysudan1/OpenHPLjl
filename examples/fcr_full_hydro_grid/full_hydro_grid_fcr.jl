using OpenHPLjl
using ModelingToolkit
using OrdinaryDiffEq
using SciMLBase

# Reservoir -> headrace -> surge tank -> penstock -> turbine -> generator/grid
# A 10% grid-load increase is applied at t = 5 s.
# All hydraulic variables are normalized around the initial operating point so
# the example stays compact and focuses on the coupled FCR dynamics.

const STEP_TIME = 5.0
const F0 = 50.0

# Initial operating point
const q0 = 0.8
const u0 = 0.8
const hs0 = 1.0
const P0 = 0.8
const P1 = 0.88              # +10% load

# Hydraulic parameters
const r_h = 0.03
const r_p = 0.03
const hres0 = hs0 + r_h*q0^2
const Ht0 = hs0 - r_p*q0^2
const k_t = Ht0
const T_res = 200.0
const T_h = 2.5
const T_s = 10.0
const T_p = 1.5
const q_in = q0

# Governor/grid parameters
const T_g = 0.30
const R = 0.04
const u_min = 0.20
const u_max = 1.05
const H_grid = 8.0
const D_grid = 1.5

@variables begin
    h_res(t) = hres0
    q_h(t) = q0
    h_s(t) = hs0
    q_p(t) = q0
    u(t) = u0
    omega_pu(t) = 1.0

    H_t(t) = Ht0
    P_m(t) = P0
    P_load(t) = P0
    u_cmd(t) = u0
    f(t) = F0
end

# Component equations, grouped by physical subsystem.
eqs = [
    # Reservoir
    T_res * D(h_res) ~ q_in - q_h,

    # Headrace water-column dynamics
    T_h * D(q_h) ~ h_res - h_s - r_h*q_h*abs(q_h),

    # Surge tank storage
    T_s * D(h_s) ~ q_h - q_p,

    # Turbine hydraulic head and penstock water-column dynamics
    H_t ~ k_t * (q_p / max(u, 0.10))^2,
    T_p * D(q_p) ~ h_s - H_t - r_p*q_p*abs(q_p),

    # Reduced turbine power around the operating point
    P_m ~ P0 * (q_p/q0) * (u/u0),

    # Grid load disturbance
    P_load ~ ifelse(t < STEP_TIME, P0, P1),

    # Primary-frequency governor
    u_cmd ~ min(u_max, max(u_min, u0 + (1.0 - omega_pu)/R)),
    T_g * D(u) ~ u_cmd - u,

    # Equivalent grid frequency dynamics
    2H_grid * D(omega_pu) ~ P_m - P_load - D_grid*(omega_pu - 1.0),
    f ~ F0 * omega_pu,
]

@named hydro_grid_fcr = ODESystem(
    eqs,
    t,
    [h_res, q_h, h_s, q_p, u, omega_pu, H_t, P_m, P_load, u_cmd, f],
    [],
)

sys = mtkcompile(hydro_grid_fcr)
prob = ODEProblem(sys, [], (0.0, 60.0))
sol = solve(prob, Rodas5P(); tstops=[STEP_TIME], abstol=1e-8, reltol=1e-8)

SciMLBase.successful_retcode(sol.retcode) || error("FCR simulation failed")

println("Reservoir-to-grid FCR study")
println("retcode = ", sol.retcode)
println("frequency minimum [Hz] = ", minimum(sol[f]))
println("frequency final [Hz] = ", sol[f][end])
println("mechanical power maximum [pu] = ", maximum(sol[P_m]))
println("mechanical power final [pu] = ", sol[P_m][end])
println("guide vane maximum [pu] = ", maximum(sol[u]))
println("surge level minimum [pu] = ", minimum(sol[h_s]))
println("surge level maximum [pu] = ", maximum(sol[h_s]))
