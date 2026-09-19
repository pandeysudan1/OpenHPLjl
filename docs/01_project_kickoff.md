# Project Kickoff

## Objective

Build a transparent, equation-based hydropower modeling and analysis library in Julia using ModelingToolkit.jl and the SciML ecosystem.

## Core principle

Each model starts from physics, not software structure:

1. identify the physical boundary;
2. write conservation laws;
3. define constitutive/algebraic relations;
4. define connector variables and sign conventions;
5. identify states, algebraic variables, parameters, and initial conditions;
6. check equation/unknown consistency;
7. compile the assembled symbolic system;
8. simulate a controlled test;
9. compare against an analytical, literature, measurement, or OpenHPL reference;
10. interpret the engineering outputs.

## First milestone

The first milestone is the hydraulic foundation:

```text
HydraulicPort -> Reservoir -> RigidPipe
```

The reservoir introduces storage and mass conservation. The rigid pipe introduces momentum balance and water inertia. Together they establish the equation-based modeling conventions used by the rest of the package.

## Definition of done for a component

A component is not considered complete when it only compiles. It should have:

- documented assumptions;
- governing equations;
- variables, parameters, units, and initial conditions;
- connector definition;
- equation/unknown consistency;
- one minimal simulation;
- one validation check;
- expected outputs;
- an engineering interpretation.

## Planned analysis layer

After the physical plant is assembled, the same model should support nonlinear simulation, linearization, eigenvalue analysis, frequency response, parameter estimation, sensitivity, optimization, governor studies, AGC, and FCR-oriented analysis.
