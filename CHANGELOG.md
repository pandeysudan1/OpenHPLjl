# Changelog

## v0.1.0-alpha.1 — Core Components Baseline

First engineering checkpoint for OpenHPLjl.

### Added

- Acausal physical interfaces
  - `HydraulicPort`
  - `RotationalPort`
  - `ElectricalPowerPort`
- Reservoir models
  - `InfiniteReservoir`
  - finite-area `Reservoir`
- Waterway models
  - `RigidPipe`
  - `SurgeTank`
- Friction model family and registry
  - no friction
  - quadratic `R Q |Q|`
  - constant Darcy factor
  - laminar `64/Re`
  - Haaland
  - Swamee-Jain
  - Colebrook residual
- Turbine models
  - `IdealTurbine`
  - `SimpleGateTurbine`
- Mechanical model
  - `LumpedShaft`
- Electrical models
  - `IdealGenerator`
  - `InfiniteGrid`
- Analytical component tests
- Reports 1–8 with compiled PDFs
- CI workflows for Julia package tests and technical-report builds

### Architecture

The package now supports the component chain

```text
Reservoir
  -> RigidPipe
  -> SurgeTank
  -> Turbine
  -> Shaft
  -> Generator
  -> Grid
```

### Scope of this checkpoint

This release establishes the core component API and model-family structure.
It does **not** yet claim a validated complete hydropower plant simulation.

Not yet included:

- fully connected hydraulic-to-grid plant assembly
- turbine lookup/Hill-chart model
- detailed Francis/Pelton/Kaplan turbine models
- elastic penstock / water-hammer model
- detailed synchronous-machine model
- governor and droop control
- AGC / tie-line control
- SMIB validation
- Trollheim calibration
- FCR/FREKI validation

### Next milestone

`v0.2.0-alpha` — Connected Plant Baseline

- assemble hydraulic train
- assemble turbine-shaft-generator-grid train
- create first complete SMIB
- validate initialization and transient simulation
