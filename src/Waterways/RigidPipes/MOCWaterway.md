# Method-of-Characteristics waterway

Status: **planned**

High-fidelity water-hammer family based on characteristic lines of the elastic
pipe PDEs. Intended for fast pressure-wave studies.

OpenHPLjl implementation route:
1. HydraulicPort boundary conditions.
2. Spatial grid and wave travel time.
3. characteristic compatibility equations.
4. friction model from FrictionModels.
5. cross-validation against ElasticPenstock semi-discretization.
