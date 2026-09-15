using OpenHPLjl
using ModelingToolkit
using OrdinaryDiffEq
using SciMLBase

# Minimal component-wise electromechanical proof:
#
# MechanicalPower -> RotationalContact -> ClassicalGenerator
#                                         |
#                                  ElectricalContact
#                                         |
#                                   LosslessLine
#                                         |
#                                     InfiniteBus
#
# At t = 5 s, mechanical power steps from 0.80 pu to 0.88 pu.

const SBASE = 100.0e6
const PM0 = 0.80
const PM1 = 0.88
const STEP_TIME = 5.0
const XLINE = 0.60

# Initial electrical equilibrium: P = sin(delta)/X.
const DELTA0 = asin(PM0 * XLINE)

@named prime_mover = PowerToTorque(
    P0 = PM0 * SBASE,
    use_power_input = true,
)

@named generator = ClassicalSynchronousGenerator(
    Sbase = SBASE,
    H = 4.0,
    damping = 1.0,
    f_grid = 50.0,
    poles = 12,
    V0 = 1.0,
    delta0 = DELTA0,
)

@named line = LosslessLine(X = XLINE)
@named grid = InfiniteBus(V = 1.0, theta = 0.0)

eqs = [
    connect(prime_mover.shaft, generator.mech),
    connect(generator.terminal, line.a),
    connect(line.b, grid.terminal),
    prime_mover.P ~ ifelse(t < STEP_TIME, PM0 * SBASE, PM1 * SBASE),
]

@named system = ODESystem(
    eqs,
    t;
    systems = [prime_mover, generator, line, grid],
)

sys = mtkcompile(system)
prob = ODEProblem(sys, [], (0.0, 20.0))
sol = solve(
    prob,
    Rodas5P();
    tstops = [STEP_TIME],
    abstol = 1e-8,
    reltol = 1e-8,
)

println("Component-wise SMIB example")
println("retcode = ", sol.retcode)
println("initial frequency [Hz] = ", sol[generator.f][1])
println("minimum frequency [Hz] = ", minimum(sol[generator.f]))
println("maximum frequency [Hz] = ", maximum(sol[generator.f]))
println("final frequency [Hz] = ", sol[generator.f][end])
println("final electrical power [pu] = ", sol[generator.P_e][end])
println("final rotor angle [deg] = ", rad2deg(sol[generator.delta][end]))

SciMLBase.successful_retcode(sol.retcode) || error("Component SMIB simulation failed")
