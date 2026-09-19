# Report 9 Study Plan — Core Component Model Families Overview

This branch starts the next OpenHPLjl milestone: literature-guided expansion of the
core model families established in v0.1.0-alpha.1.

## Objective

For every current source-domain folder, document:

1. engineering concept
2. model families available in literature
3. governing mathematics
4. OpenHPL/OpenModelica interpretation where applicable
5. Julia / ModelingToolkit / SciML implementation pattern
6. recommended next implementation level

## Current domains

- Interfaces
- Reservoirs
- FrictionModels
- Waterways / RigidPipes
- Waterways / SurgeTanks
- Turbines
- Mechanical / Shafts
- Electrical / Generators
- Electrical / Grids

## Planned output

- `docs/report_09_model_families_overview.tex`
- `docs/report_09_model_families_overview.pdf`
- README roadmap update
- literature/reference table
- implementation-priority table


## Literature anchors

Primary references used for the overview:

- OpenHPL 3.0.1 User Guide and Waterway documentation
- OpenHPL simple, Francis and Pelton turbine documentation
- OpenHPL surge-tank and Darcy-friction documentation
- ModelingToolkit acausal component documentation
- Modelica Standard Library Rotational mechanics
- OpenIPSL PSSE machine models and SMIB tests
- 2025 Energies review of rigid/elastic water-hammer models
- surge-tank review literature
- turbine hill-chart/performance-curve literature

The study intentionally distinguishes:
- reduced/control-oriented models,
- lumped nonlinear physics models,
- higher-order/distributed models,
- data/lookup-based models.
