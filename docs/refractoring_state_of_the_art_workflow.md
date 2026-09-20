# Refractoring based on state-of-the art work flow

## Purpose

This refactoring establishes a consistent development path for equation-based
hydropower models:

```text
physical law
  -> connector semantics
  -> reusable component
  -> subsystem composition
  -> structural compilation
  -> consistent initialization
  -> numerical problem
  -> simulation
  -> validation
  -> control-oriented analysis
```

The goal is not to change the physics already validated in the package. The goal
is to make every model easier to connect, initialize, test, extend and analyze.

## 1. Separate connection semantics from component physics

Physical interfaces define only the variables that cross a connection boundary.

| Domain | Potential / across variable | Conserved flow variable |
|---|---|---|
| Hydraulic | head `H` | volumetric flow `Q` |
| Rotational | angular speed `omega` | torque `tau` |
| Reduced electrical | angular frequency `omega` | active power `P` |

The flow convention remains **positive into a component**. Connected flow
variables therefore sum to zero.

The three physical interfaces now use explicit ModelingToolkit connector
definitions. Constitutive equations remain inside the components.

## 2. Add a distinct signal layer

Controls, disturbances and measurements are not physical potential/flow
connections. They therefore use causal scalar signal connectors:

```text
SignalPlug  ->  SignalSocket
   output          input
```

This prevents a controller or test signal from being hidden inside a turbine,
generator or waterway model.

The first reusable source is `ConstantSignal`. Its center value is a tunable
parameter so the same compiled component can be reused in operating-point and
control studies.

## 3. Keep component models orthogonal

A component should solve one physical purpose whenever practical.

Examples:

- reservoir: storage / boundary head,
- rigid pipe: water-column momentum,
- surge tank: local hydraulic storage,
- turbine: hydraulic-to-mechanical conversion,
- shaft: rotational inertia,
- generator: mechanical-to-electrical conversion,
- grid: electrical frequency boundary,
- signal source: command generation.

This avoids components that simultaneously impose incompatible boundary
conditions and makes component reuse predictable.

## 4. Preserve a flat mathematical contract inside every component

Each component should be readable in the following order:

```text
parameters
states and algebraic variables
subcomponents / ports
equations
System(...)
```

For dynamic components, the equations should start from conservation laws or
the primary balance relation. Algebraic constitutive relations follow.

Examples:

### Reservoir

```math
A\dot H = Q_{in} + Q_{port}
```

### Rigid pipe

```math
\dot Q = \frac{gA}{L}\left(H_{in}-H_{out}-h_f(Q)\right)
```

### Surge tank

```math
A_s\dot H_s = Q_{in}+Q_{out}
```

### Shaft

```math
J\dot\omega =
\tau_{drive}+\tau_{load}
-D(\omega-\omega_0)
```

## 5. Separate control-ready models from compatibility models

The existing `SimpleGateTurbine` remains available so existing examples are not
broken.

A new `ControlledGateTurbine` exposes the guide-vane command as a signal input:

```text
ConstantSignal / Governor / AGC / TestSignal
                  |
                  v
              gate.u
                  |
                  v
        ControlledGateTurbine
```

Its equations are

```math
H = H_{in}-H_{out}
```

```math
y = u_{gate}
```

```math
Q = K_q y \sqrt{H}
```

```math
P_m = \rho g \eta QH .
```

This is the bridge from the current component catalogue to governors, AGC,
measurement blocks and FCR excitation signals.

## 6. Compose first, compile second

For complete plant models, instantiate components and express only the
connections at the system level:

```julia
@named source = ConstantSignal(u0 = 0.5)
@named turbine = ControlledGateTurbine()

eqs = [
    connect(source.y, turbine.gate)
]

@named plant = System(
    eqs,
    t;
    systems = [source, turbine],
)
```

The uncompiled hierarchy is kept for inspection and debugging. Compilation is a
separate step:

```julia
compiled = mtkcompile(plant)
```

Structural compilation performs connection expansion, structural
simplification, alias elimination and index reduction as required.

## 7. Treat initialization as part of the model

For a compiled nonlinear system, distinguish:

- differential variables: provide physical initial values,
- algebraic variables: provide physically meaningful guesses when needed,
- observed variables: compute from the solved variables rather than
  over-specifying them.

For hydropower systems, the initial operating point should eventually be built
from a steady hydraulic/electromechanical balance before disturbances are
applied.

The recommended workflow is:

```text
choose operating point
 -> set physical state initial values
 -> set algebraic guesses
 -> mtkcompile
 -> build ODEProblem / DAEProblem
 -> solve initialization
 -> verify residuals
 -> simulate disturbance
```

## 8. Verification ladder

Every new component or refactor should pass four levels.

### Level A — structural

- package loads,
- connector variables exist,
- expected parameters and unknowns exist,
- system hierarchy is preserved.

### Level B — analytical

Compare a simple case with a hand-computable result.

Current examples include:

- reservoir mass balance,
- rigid-pipe constant-head acceleration,
- surge-tank level balance,
- shaft constant-torque acceleration.

### Level C — composition

Connect components through their public ports rather than by reaching into
internal equations.

The new signal-ready turbine test verifies this composition path.

### Level D — numerical

Compile the assembled system and solve it with the current Julia /
ModelingToolkit / OrdinaryDiffEq environment in CI.

## 9. Control and linearization preparation

Control studies should keep the following two model views:

```text
uncompiled hierarchical model
    -> composition, control inputs, analysis points, model inspection

compiled model
    -> simulation, initialization, reduced unknown set, numerical solution
```

For later linearization, explicit signal inputs must remain identifiable before
structural elimination. This is the reason the gate command is now represented
as a connector rather than only as a turbine parameter.

## 10. Package organization after this refactor

```text
src/
├── Interfaces/
│   ├── HydraulicPort.jl
│   ├── RotationalPort.jl
│   ├── ElectricalPowerPort.jl
│   └── SignalPort.jl
├── Signals/
│   └── ConstantSignal.jl
├── Reservoirs/
├── Waterways/
├── FrictionModels/
├── Turbines/
│   ├── IdealTurbine.jl
│   ├── SimpleGateTurbine.jl
│   └── ControlledGateTurbine.jl
├── Mechanical/
├── Electrical/
└── OpenHPLjl.jl
```

## 11. Compatibility strategy

This branch is intentionally evolutionary:

- existing core component names are retained,
- existing physics equations are retained,
- the original `SimpleGateTurbine` is retained,
- the connector API is expressed using current ModelingToolkit connector
  semantics,
- new signal-ready components are additive.

Future breaking API changes should wait until the first complete SMIB is
assembled and validated.

## 12. Next implementation milestone

The next branch should build a complete reduced SMIB using this sequence:

```text
InfiniteReservoir
 -> RigidPipe
 -> SurgeTank
 -> RigidPipe / Penstock
 -> ControlledGateTurbine
 -> Shaft
 -> Generator
 -> Grid

frequency measurement
 -> governor
 -> gate signal
```

Verification should include:

1. equation/unknown count before and after compilation,
2. initialization residuals,
3. steady-state power balance,
4. a guide-vane step,
5. shaft-speed/frequency response,
6. hydraulic-head and flow response,
7. energy/power consistency,
8. CI on the current supported Julia and package versions.
