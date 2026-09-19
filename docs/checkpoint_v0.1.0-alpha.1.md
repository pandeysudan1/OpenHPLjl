# Core Components Baseline

**Checkpoint:** `v0.1.0-alpha.1`

This checkpoint marks completion of the first OpenHPLjl core-component pass.

## Included model families

```text
Interfaces
├── HydraulicPort
├── RotationalPort
└── ElectricalPowerPort

Hydraulics
├── InfiniteReservoir
├── Reservoir
├── RigidPipe
├── SurgeTank
└── FrictionModels registry

Turbines
├── IdealTurbine
└── SimpleGateTurbine

Mechanical
└── LumpedShaft

Electrical
├── IdealGenerator
└── InfiniteGrid
```

## Governing physical ideas

- reservoir and surge tank: mass/storage balance
- rigid pipe: momentum / water inertia
- friction: selectable constitutive head-loss laws
- turbine: hydraulic-to-mechanical power conversion
- shaft: rotational inertia
- generator: mechanical-to-electrical power conversion
- grid: infinite-bus frequency boundary

## Validation level

Each model family has a small analytical test or structural test. This is a
core-component checkpoint, not yet a full-plant validation release.

## Next checkpoint

The next milestone will connect the components into subsystem assemblies and a
first hydropower SMIB model.
