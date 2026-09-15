# OpenHPLjl

`OpenHPLjl` is an experimental Julia/ModelingToolkit translation of the Modelica hydropower library [OpenHPL](https://github.com/OpenSimHub/OpenHPL).

The goal is to preserve OpenHPL's physical equations and acausal component philosophy while making the models composable with the SciML/ModelingToolkit ecosystem.

## Current scope

Implemented:

- hydraulic `Contact` connector
- `Reservoir`
- `HydroPipe` using the OpenHPL momentum equation and Darcy friction
- simple `SurgeTank` (`STSimple` physics)
- `PressureBoundary`
- simple hydraulic `Turbine`
- rotor-energy-balance `SimpleGenerator`
- first-order `DroopGovernor`
- fixed-opening and controlled-opening turbine modes
- fixed-load and externally driven load modes
- CI smoke tests and runnable examples

Still to translate or validate:

- air-cushion, sharp-orifice and throttle surge tanks
- creek intake
- Francis, Pelton and empirical turbine models
- detailed generator / grid models
- transient droop, PID and other OpenHPL controllers
- Modelica-vs-Julia trajectory validation
- elastic penstock / distributed water-hammer models

## Architecture

```text
OpenHPL Modelica                     OpenHPLjl / ModelingToolkit
----------------                     --------------------------
Interfaces.Contact       -------->   Contact()
Waterway.Reservoir       -------->   Reservoir()
Waterway.Pipe            -------->   HydroPipe()
Waterway.SurgeTank       -------->   SurgeTank()
ElectroMech.Turbines     -------->   Turbine()
Generators.SimpleGen     -------->   SimpleGenerator()
Controllers              -------->   DroopGovernor()
Examples                 -------->   executable plant studies
```

`HydroPipe` is used instead of the Julia name `Pipe` because `Base.Pipe` is already a Julia process/IO type.

## Modeling philosophy

The package is equation based:

```text
component equations
      -> physical connectors
      -> assembled DAE
      -> mtkcompile
      -> initialize
      -> solve
```

This keeps the hydraulic and electromechanical subsystems in one nonlinear model and leaves operating-point calculation, initialization, linearization and control studies inside the SciML workflow.

## First nonlinear hydro unit

```text
Reservoir
   -> Headrace
   -> SurgeTank
   -> Penstock
   -> Turbine
   -> Tailrace

Turbine mechanical power
   -> SimpleGenerator
   -> frequency
   -> DroopGovernor
   -> turbine guide-vane opening
```

The first FCR-style example is:

```text
examples/fcr_load_step.jl
```

It applies a 10% electrical load increase at `t = 5 s` and closes the primary-frequency loop through the governor and turbine opening.

The governing reduced equations are

```text
Pipe:
L d(mdot)/dt = (p_i + rho g H - p_o) A - F_f

Turbine:
dp (C_v max(epsilon,u^alpha))^2 = Q |Q|
P_t = eta_h dp Q

Generator:
J omega domega/dt = P_m - P_load - P_fric

Governor:
u_cmd = sat(u0 + (f_ref - f)/(R f_ref))
T_g du/dt = u_cmd - u
```

## Examples

```text
examples/reservoir_pipe.jl
examples/reservoir_surge_penstock.jl
examples/reservoir_surge_turbine.jl
examples/hydro_unit_frequency.jl
examples/fcr_load_step.jl
```

## Development

```julia
using Pkg
Pkg.instantiate()

using OpenHPLjl
using ModelingToolkit

@named reservoir = Reservoir()
@named penstock = HydroPipe(H = 100.0, L = 700.0, D_i = 2.0)
```

See `docs/TRANSLATION_PLAN.md` for the component-by-component migration and validation plan.

## Validation

A translated component is not considered validated only because it compiles. The intended validation sequence is:

1. identify the exact upstream OpenHPL source/version
2. match parameters and operating point
3. run Modelica and Julia cases
4. compare steady state and transient trajectories
5. record numerical error and tolerances
6. add the case to CI

## Railway

A Railway project named `OpenHPLjl` has been created for cloud execution. Deployment of a Julia service is currently separate from the library code and depends on available Railway account resources. GitHub Actions is used as the immediate executable validation path.

## License and provenance

OpenHPL is distributed under the Mozilla Public License 2.0. Files in this repository that translate or adapt OpenHPL equations are marked `SPDX-License-Identifier: MPL-2.0` and retain source provenance. This project is not an official OpenHPL distribution.
