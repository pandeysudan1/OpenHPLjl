# OpenHPLjl

**Equation-based hydropower modeling and analysis in Julia with ModelingToolkit.jl and the SciML ecosystem.**

## Project motivation

Hydropower dynamics couple several physical domains: reservoir storage, waterway inertia, surge oscillations, turbine characteristics, rotating-machine dynamics, control systems, and the electrical grid. These interactions are naturally described by differential-algebraic equations rather than by a collection of one-way signal blocks.

OpenHPLjl is a fresh Julia project for building these systems from physical conservation laws and reusable acausal components. The immediate goal is not to reproduce every OpenHPL component line-for-line. The goal is to establish a transparent modeling framework in which the mathematics, assumptions, initialization, numerical solution, and engineering interpretation remain visible.

The project uses **ModelingToolkit.jl** for symbolic and equation-based model construction and the broader **SciML** ecosystem for compilation, numerical integration, parameter analysis, sensitivity, calibration, optimization, and control-oriented analysis.

## Generalized hydropower concept

```text
Reservoir
   |
   v
Intake / waterway
   |
   v
Surge tank
   |
   v
Penstock
   |
   v
Turbine --> Shaft --> Generator --> Grid
   ^                                  |
   |                                  v
   +----------- Governor <--------- Frequency
```

The modeling principle is:

```text
physical law
    -> component equations
    -> acausal connectors
    -> assembled DAE/ODE system
    -> consistent initialization
    -> numerical simulation
    -> analysis and validation
```

## Modeling scope

Each component will be documented in the same order:

1. Updated engineering context
2. Generalized concept model
3. Alternative models available in the literature
4. Mathematics used in the OpenHPL/OpenHPLjl concept
5. OpenHPL-specific modeling interpretation
6. Julia ModelingToolkit / SciML implementation
7. Component connections and model assembly
8. Numerical experiment and validation
9. Expected outputs
10. Engineering interpretation

## Mathematical viewpoint

A general component may contain differential states `x`, algebraic variables `z`, inputs or external quantities `u`, and parameters `p`:

```math
\dot{x} = f(x,z,u,p)
```

```math
0 = g(x,z,u,p)
```

Hydraulic components will begin from mass and momentum conservation. Mechanical components will use torque and rotational dynamics. Electrical components will progress from simple power/frequency representations toward richer synchronous-machine and grid models where necessary.

The assembled plant therefore becomes a nonlinear DAE system that can be compiled and analyzed using ModelingToolkit and SciML tools.

## Why ModelingToolkit.jl?

ModelingToolkit supports symbolic equation systems, hierarchical components, acausal connections, structural transformations, index reduction, initialization, generated numerical functions, and integration with SciML solvers. Current ModelingToolkit documentation uses `mtkcompile` to transform a symbolic `System` into a numerically solvable form.

The project will prefer current public ModelingToolkit APIs and will avoid depending on internal APIs unless there is a clear reason.

## Analysis roadmap

OpenHPLjl is intended to support more than time-domain simulation. Planned analyses include:

- steady-state and operating-point initialization
- nonlinear transient simulation
- component step and ramp validation
- hydraulic oscillation analysis
- turbine characteristic-map studies
- small-signal linearization
- eigenvalue and damping analysis
- frequency-response analysis
- Bode and Nyquist analysis
- governor and droop studies
- AGC and tie-line control
- FCR response and prequalification studies
- parameter estimation and model validation
- sensitivity analysis
- optimization and control design

## Package structure

```text
OpenHPLjl/
├── src/
│   ├── Interfaces/
│   │   └── HydraulicPort.jl
│   ├── Reservoirs/
│   │   ├── InfiniteReservoir.jl
│   │   └── Reservoir.jl
│   └── OpenHPLjl.jl
├── test/
│   └── runtests.jl
├── docs/
├── examples/
├── Project.toml
└── README.md
```

The folders will be expanded only when the corresponding physical model is introduced.

## First modeling sequence

The initial component sequence is deliberately simple:

```text
HydraulicPort
    -> Reservoir
    -> RigidPipe
    -> SurgeTank
    -> Penstock
    -> Turbine
    -> Shaft
    -> Generator
    -> Grid
    -> Governor
    -> complete hydropower plant
```

### Step 1 — Hydraulic connector

Define the effort-like hydraulic variable and the conserved flow variable with a consistent sign convention and units.

### Step 2 — Reservoir

Start from mass conservation:

```math
\frac{dV}{dt}=Q_{in}-Q_{out}.
```

Implement both constant-head and finite-storage variants and validate the storage balance.

### Step 3 — Rigid waterway

Introduce momentum conservation and water inertia.

### Step 4 — Surge tank

Add storage-waterway interaction and verify the natural hydraulic oscillation.

### Step 5 — Turbine

Connect hydraulic and rotational domains using an analytical model first, then a characteristic-map/lookup-table model.

### Step 6 — Shaft, generator, and grid

Build the mechanical/electrical chain and establish an SMIB test case.

### Step 7 — Control

Add isochronous control, droop, AGC, and later interconnected-area control.

### Step 8 — Analysis

Use the assembled model for operating-point analysis, linearization, eigenvalues, Bode/Nyquist plots, time-domain disturbances, and FCR studies.

## Expected outputs

As the package grows, examples should produce physically interpretable quantities rather than only solver success messages.

Typical hydraulic outputs:

- reservoir head and volume
- discharge
- penstock head/pressure
- surge-tank level
- hydraulic power

Typical turbine/mechanical outputs:

- guide-vane position
- turbine flow
- efficiency
- mechanical power and torque
- shaft speed

Typical electrical/control outputs:

- electrical power
- rotor angle
- frequency deviation
- governor command
- FCR activation power and energy

Every major component should have at least one numerical validation experiment and a clearly stated expected result.

## Development flow

### Previous commits

The fresh kickoff established a minimal ModelingToolkit/SciML package and removed the older experimental scaffolding from the active tree. The next commits added **Report 1 - Reservoir Model** in LaTeX and linked it from this README.

The current baseline on `main` is therefore:

```text
fresh package kickoff
    -> reservoir modeling report
    -> README/report integration
```

### Current branch - `rigid-pipe-model`

This branch adds the first waterway momentum model on top of the reservoir milestone. It includes Report 2, the `RigidPipe` source model, and an analytical momentum-balance test.

Current branch flow:

```text
Report 1 mathematics
    -> HydraulicPort
    -> InfiniteReservoir
    -> DynamicReservoir
    -> analytical mass-balance tests
    -> simulation/validation plots
```

### Current source milestone

The first equation-based source components are now organized as:

```text
src/
├── Interfaces/
│   └── HydraulicPort.jl
├── Reservoirs/
│   ├── InfiniteReservoir.jl
│   └── Reservoir.jl
└── OpenHPLjl.jl
```

The hydraulic sign convention is **flow positive into a component**. The finite reservoir therefore uses

```math
A\dot H = Q_{in} + Q_{port}.
```

For generation outflow, `Q_port < 0`.

### Next commit

The next implementation commit should add:

- one minimal reservoir simulation example under `examples/`
- expected-output plots for head and flow
- a nonlinear-geometry reservoir variant
- equation/unknown-count diagnostics
- CI timing summary from the real Julia 1.12 / ModelingToolkit 11 run
- documentation links from this README

After the reservoir component is validated, the next modeling branch should introduce the **RigidPipe** from momentum conservation and water inertia.

## Next steps

- [ ] Define notation, SI units, sign conventions, and modeling rules.
- [x] Implement `HydraulicPort`.
- [x] Write **Report 1: Reservoir** in `docs/report_01_reservoir.tex`.
- [x] Compile Report 1 to `docs/report_01_reservoir.pdf` on the `reservoir-model` branch.
- [x] Implement constant-head reservoir.
- [x] Implement finite-storage reservoir.
- [x] Add analytical reservoir mass-balance tests.
- [x] Implement `RigidPipe` from momentum balance.
- [x] Add analytical head-step test for the first waterway.
- [x] Introduce basic `SurgeTank` storage model and analytical mass-balance test.
- [ ] Validate the coupled RigidPipe-SurgeTank oscillation.
- [ ] Add turbine model and characteristic lookup-table interface.
- [ ] Assemble the first reservoir-to-turbine hydraulic system.
- [ ] Add shaft, generator, infinite bus, and governor models.
- [ ] Build a complete SMIB example.
- [ ] Add analysis examples using SciML and control-system tooling.
- [ ] Extend the validated model toward Trollheim, AGC, and FCR studies.

## Status

This commit is the **fresh project kickoff**. Previous experimental package contents were intentionally removed from the active tree. They remain available through Git history.

The first technical milestone is a tested hydraulic connector plus reservoir model.

## Technical reports

- **Report 1 - Reservoir Model:** `docs/report_01_reservoir.tex`
- **Compiled Report 1 PDF:** `docs/report_01_reservoir.pdf`
  - updated engineering context
  - generalized concept model
  - literature model hierarchy
  - OpenHPL mathematics and interpretation
  - ModelingToolkit/SciML implementation
  - connection semantics
  - numerical validation
  - expected outputs and engineering interpretation

Compile locally with a standard LaTeX distribution, for example:

```bash
cd docs
pdflatex report_01_reservoir.tex
pdflatex report_01_reservoir.tex
```

- **Report 2 - Rigid Pipe Model:** `docs/report_02_rigid_pipe.tex`
- **Compiled Report 2 PDF:** `docs/report_02_rigid_pipe.pdf`

Report 2 is intentionally concise and follows the same 10-part structure as Report 1.

The basic **SurgeTank** component is now included in `src/Waterways/SurgeTank.jl`.

Its storage equation is

```math
A_s \dot H_s = Q_{in} + Q_{out},
```

using the package convention that port flow is positive into a component.

The next validation step is a **coupled RigidPipe-SurgeTank system**, where water inertia and tank storage create the first hydraulic oscillatory mode.


- **Report 3 - Surge Tank Model:** `docs/report_03_surge_tank.tex`
- **Compiled Report 3 PDF:** `docs/report_03_surge_tank.pdf`

Report 3 follows the same concise 10-part structure and documents the storage equation, MTK implementation, analytical mass-balance test, expected outputs, and the next coupled RigidPipe-SurgeTank oscillation study.


## Turbine model family

Turbines are organized by model fidelity rather than as one monolithic model.

```text
Turbines/
├── IdealTurbine.jl
├── SimpleGateTurbine.jl
├── TurbineLookup.jl      # planned
├── FrancisTurbine.jl     # planned
├── PeltonTurbine.jl      # planned
└── KaplanTurbine.jl      # planned
```

The first two models use the same hydraulic connector as the waterways.

### IdealTurbine

```math
H = H_{in}-H_{out},
\qquad
P_m = \rho g\eta QH.
```

The surrounding network determines `Q`.

### SimpleGateTurbine

```math
Q = K_q y\sqrt{H},
\qquad
P_m = \rho g\eta QH.
```

This is the first controllable turbine approximation. The next higher-fidelity model will replace the analytical gate law and constant efficiency with characteristic maps / lookup tables.

The waterway models are also now grouped as model families under `Waterways/RigidPipes/` and `Waterways/SurgeTanks/`, making it straightforward to add elastic pipes, throttled surge tanks, variable-area surge tanks, and other alternatives.


- **Report 4 - Turbine Model Family:** `docs/report_04_turbine_models.tex`
- **Compiled Report 4 PDF:** `docs/report_04_turbine_models.pdf`

Report 4 introduces the turbine model hierarchy from ideal hydraulic-power conversion to guide-vane, lookup/Hill-chart, and type-specific Francis/Pelton/Kaplan models.


## Friction model family

Hydraulic loss laws are separated from the RigidPipe momentum equation.

```text
src/FrictionModels/
├── FrictionFunctions.jl
├── FrictionRegistry.jl
└── README.md
```

Registered models:

- `:none`
- `:quadratic` — (H_f = RQ|Q|)
- `:darcy_constant` — Darcy-Weisbach with prescribed (f_D)
- `:darcy_laminar` — (f_D = 64/Re)
- `:darcy_haaland`
- `:darcy_swamee_jain`

The implicit Colebrook-White equation is provided as a residual for later use with `NonlinearSolve.jl`.

A pipe selects its law at construction time:

```julia
@named pipe = RigidPipe(
    friction = :darcy_haaland,
    L = 1000.0,
    diameter = 3.0,
    nu = 1e-6,
    epsilon = 1e-4,
)
```

This keeps

```math
\frac{L}{gA}\dot Q = H_{in}-H_{out}-H_f(Q)
```

independent of the chosen friction correlation.

- **Report 5 - Friction Model Registry:** `docs/report_05_friction_models.tex`
- **Compiled Report 5 PDF:** `docs/report_05_friction_models.pdf`

Next: compare the registered laws in one RigidPipe simulation, then add transitional and unsteady-friction models where justified.


## Shaft, generator, and grid model families

The electromechanical side now follows the same model-family structure as the waterways and turbines.

```text
src/
├── Interfaces/
│   ├── RotationalPort.jl
│   └── ElectricalPowerPort.jl
├── Mechanical/
│   └── Shafts/
│       ├── LumpedShaft.jl
│       └── README.md
└── Electrical/
    ├── Generators/
    │   ├── IdealGenerator.jl
    │   └── README.md
    └── Grids/
        ├── InfiniteGrid.jl
        └── README.md
```

### LumpedShaft

```math
J\dot\omega
=
\tau_{drive}
+
\tau_{load}
-
D(\omega-\omega_0).
```

### IdealGenerator

```math
P_m = \tau\omega,
\qquad
P_e = \eta_g P_m.
```

### InfiniteGrid

```math
\omega = 2\pi f_0.
```

The next coupled milestone is a reduced electromechanical chain:

```text
Turbine -> Shaft -> Generator -> InfiniteGrid
```

followed by a complete hydraulic-to-grid SMIB model.


## Electromechanical technical reports

- **Report 6 - Shaft Model Family:** `docs/report_06_shaft_models.tex`
- **Compiled Report 6 PDF:** `docs/report_06_shaft_models.pdf`
- **Report 7 - Generator Model Family:** `docs/report_07_generator_models.tex`
- **Compiled Report 7 PDF:** `docs/report_07_generator_models.pdf`
- **Report 8 - Grid Model Family:** `docs/report_08_grid_models.tex`
- **Compiled Report 8 PDF:** `docs/report_08_grid_models.pdf`

The progression is now:

```text
Hydraulics -> Turbine -> Shaft -> Generator -> Grid
```

Next: connect these components into one reduced electromechanical chain, then assemble the first complete hydropower SMIB example.
