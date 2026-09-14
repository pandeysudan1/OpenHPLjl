# OpenHPL -> OpenHPLjl translation plan

Source library: `OpenSimHub/OpenHPL` (Modelica, MPL-2.0).
Target: `OpenHPLjl` using ModelingToolkit.jl for acausal ODE/DAE composition.

## Translation philosophy

The goal is **equation-equivalent Julia models**, not line-by-line syntax conversion.
For each Modelica component we preserve:

1. physical states and algebraic variables,
2. mass/momentum/energy balances,
3. connector potential/flow semantics,
4. initialization equations and operating-point assumptions,
5. parameters and units,
6. validation against the corresponding OpenHPL example.

Modelica `flow` variables map to ModelingToolkit connector variables with `connect = Flow`.
Modelica connection equations map to MTK `connect(...)` equations. Modelica overconstrained
elevation handling will be represented explicitly at system assembly level until an equivalent
robust graph/root formulation is implemented in Julia.

## Migration order

| Phase | OpenHPL area | OpenHPLjl target | Status |
|---|---|---|---|
| 0 | Package + interfaces | `src/OpenHPLjl.jl`, `src/Interfaces.jl` | started |
| 1 | Reservoir | `src/Waterway.jl` | default DAE started |
| 2 | Pipe / conduit | `src/Waterway/Pipe.jl` | next |
| 3 | Surge tank | `src/Waterway/SurgeTank.jl` | planned |
| 4 | Valve / fittings / draft tube | `src/Waterway/*` | planned |
| 5 | Simple turbine | `src/ElectroMech/Turbines.jl` | planned |
| 6 | Francis turbine | `src/ElectroMech/Francis.jl` | planned |
| 7 | Generator + shaft | `src/ElectroMech/Generators.jl` | planned |
| 8 | Governor/controllers | `src/Controllers.jl` | planned |
| 9 | Full examples | `examples/` | planned |
| 10 | Penstock PDE/KP models | `src/Waterway/PenstockKP.jl` | later |

## Validation rule

Every translated component should have:

- a Modelica reference file and upstream commit/tag recorded,
- a Julia unit test,
- one matched operating point,
- one transient comparison,
- numerical tolerances stated explicitly,
- plots or tabulated error metrics where useful.

The first system-level target is the OpenHPL `SimpleTurbine` example: reservoir -> pipe -> turbine -> tailwater.
After that, add surge tank and generator/governor models.

## Railway role

Railway project: `openhpl-modelica-backend`.
The `OpenHPLjl` service is intended as a reproducible Julia build/test runner. The existing
OpenModelica services can later provide reference trajectories, allowing automated
Modelica-vs-Julia regression tests from the same Railway project.
