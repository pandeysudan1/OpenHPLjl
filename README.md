# OpenHPLjl

`OpenHPLjl` is an experimental Julia/ModelingToolkit translation of the Modelica hydropower library [OpenHPL](https://github.com/OpenSimHub/OpenHPL).

The objective is to preserve the physical equations and acausal component philosophy of OpenHPL while making the models composable with the SciML/ModelingToolkit ecosystem.

## Current milestone

Implemented/scaffolded:

- Julia package structure
- hydraulic `Contact` connector with pressure + mass-flow semantics
- first DAE translation of the default reservoir model
- migration roadmap and validation rules
- Railway build/runtime scaffold

Next component: **Pipe**, followed by **SurgeTank** and **SimpleTurbine**.

## Architecture

```text
OpenHPL Modelica                     OpenHPLjl / ModelingToolkit
----------------                     --------------------------
Interfaces.Contact       -------->   Contact()
Waterway.Reservoir       -------->   Reservoir()
Waterway.Pipe            -------->   Pipe()             [next]
Waterway.SurgeTank       -------->   SurgeTank()        [planned]
ElectroMech.Turbines     -------->   Turbine models     [planned]
ElectroMech.Generators   -------->   Generator models   [planned]
Controllers              -------->   Governor/control   [planned]
Examples                 -------->   validated examples [planned]
```

## Why ModelingToolkit

OpenHPL is acausal: components contribute equations and connectors enforce physical coupling. ModelingToolkit is therefore a better target than rewriting every component as an explicit causal ODE. The intended workflow is:

```text
component equations -> connect components -> structural_simplify -> initialize -> solve
```

This keeps DAE initialization, operating-point calculation, linearization and control-system studies available in Julia.

## Railway

This repository is intended to run inside the existing Railway project `openhpl-modelica-backend` as a service named `OpenHPLjl`. The same Railway project already hosts OpenModelica-related services, which can later generate reference trajectories for automated Modelica-vs-Julia validation.

## Development

```julia
using Pkg
Pkg.instantiate()
using OpenHPLjl

@named reservoir = Reservoir()
reservoir
```

See `docs/TRANSLATION_PLAN.md` for the component-by-component migration and validation plan.

## License and provenance

OpenHPL is distributed under the Mozilla Public License 2.0. Files in this repository that are translations or adaptations of OpenHPL equations are marked `SPDX-License-Identifier: MPL-2.0` and retain clear source provenance. This project is not presented as an official OpenHPL distribution.
