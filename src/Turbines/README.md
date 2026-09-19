# Turbine model family

OpenHPLjl keeps turbine models in one family folder so fidelity can increase
without changing the surrounding package structure.

Current models:

- `IdealTurbine.jl` — hydraulic power conversion with flow determined by the connected network.
- `SimpleGateTurbine.jl` — adds a simple guide-vane/flow law and constant efficiency.

Planned models:

- `TurbineLookup.jl` — characteristic-map / Hill-chart lookup model.
- `FrancisTurbine.jl`
- `PeltonTurbine.jl`
- `KaplanTurbine.jl`

Each model should document assumptions, equations, parameters, expected outputs,
and at least one validation case.
