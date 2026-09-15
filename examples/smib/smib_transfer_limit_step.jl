using OpenHPLjl
using ModelingToolkit
using OrdinaryDiffEq
using SciMLBase

# Canonical single-machine infinite-bus (SMIB) example.
#
# Before t = 5 s the machine is in steady state:
#     Pm = Pe = 0.8 pu
#     Pmax = 1.5 pu
#     delta0 = asin(Pm/Pmax)
#
# At t = 5 s the network transfer limit is reduced to 1.1 pu. Mechanical
# power is held constant, so the rotor accelerates and executes a damped
# electromechanical oscillation against the infinite bus.

const H = 4.0
const DAMPING = 1.0
const F0 = 50.0
const PM = 0.8
const PMAX_PRE = 1.5
const PMAX_POST = 1.1
const STEP_TIME = 5.0
const DELTA0 = asin(PM / PMAX_PRE)

@named smib = SMIBGenerator(
    H = H,
    damping = DAMPING,
    f_grid = F0,
    Pm0 = PM,
    Pmax0 = PMAX_PRE,
    delta0 = DELTA0,
    use_pmax_input = true,
)

eqs = [
    smib.Pmax_e ~ ifelse(t < STEP_TIME, PMAX_PRE, PMAX_POST),
]

@named model = ODESystem(eqs, t; systems = [smib])
sys = mtkcompile(model)
prob = ODEProblem(sys, [], (0.0, 20.0))
sol = solve(
    prob,
    Rodas5P();
    tstops = [STEP_TIME],
    saveat = 0.01,
    abstol = 1e-9,
    reltol = 1e-9,
)

frequency = sol[smib.f]
delta_deg = rad2deg.(sol[smib.delta])
electrical_power = sol[smib.P_e]

println("OpenHPLjl SMIB transfer-limit step")
println("retcode = ", sol.retcode)
println("delta0 [deg] = ", rad2deg(DELTA0))
println("minimum frequency [Hz] = ", minimum(frequency))
println("maximum frequency [Hz] = ", maximum(frequency))
println("maximum rotor angle [deg] = ", maximum(delta_deg))
println("final frequency [Hz] = ", frequency[end])
println("final rotor angle [deg] = ", delta_deg[end])
println("final electrical power [pu] = ", electrical_power[end])

SciMLBase.successful_retcode(sol.retcode) || error("SMIB simulation failed")
