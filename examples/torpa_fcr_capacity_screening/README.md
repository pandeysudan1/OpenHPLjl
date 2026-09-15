# Torpa-like hydro FCR capacity screening

## Client question

A hydro owner wants to know the largest FCR-D Up volume that can be offered at a given operating point without failing the response-time, hydraulic or stability checks.

This example is motivated by the Nordic FCR prequalification problem, but **does not use confidential Torpa plant data**. The parameters are illustrative and are intended to be replaced by measured plant data before engineering use.

## Problem

For each operating point `P0`, droop `R` and candidate FCR capacity `C_FCR`, simulate the closed-loop hydro response to a frequency step from 50.0 Hz to 49.5 Hz.

The screening problem is

```text
maximize    C_FCR
subject to  response(7.5 s) >= 0.86 C_FCR
            response(30 s)  ~= C_FCR
            q_min <= q(t) <= q_max
            h_min <= h(t) <= h_max
            0 <= guide_vane(t) <= 1
            bounded and settling speed response
```

The first experiment matrix is deliberately small:

- operating point: 40%, 60%, 80% rated power
- candidate FCR: 5, 10, 15, 20 MW
- permanent droop: 4%, 5%, 6%

This gives 36 cases.

## Model used in this first screen

```text
frequency disturbance
        |
        v
   governor + transient droop
        |
        v
   guide vane actuator
        |
        v
 reservoir -> nonlinear waterway -> turbine -> shaft/generator -> grid
```

The current script uses a compact nonlinear waterway screening model with quadratic head loss and gate-rate limiting. The next step is to replace this hydraulic screening layer with connected OpenHPL components (reservoir, conduit, surge tank, turbine, rotational shaft, generator and grid connection).

## Run

From the repository root:

```bash
julia --project=. examples/torpa_fcr_capacity_screening/run_study.jl
```

## Outputs

The script creates:

- `results/screening_summary.csv` — all 36 cases
- `results/capacity_envelope.csv` — maximum passing FCR volume by operating point
- `results/representative_case.csv` — one 60% loading, 15 MW, 5% droop trajectory

The key result is the operating-point-dependent envelope

```text
C_FCR,max(P0)
```

rather than a single nameplate FCR number.

## Interpretation

A candidate fails for one of three reasons:

1. **Dynamic response** — too little active-power response by 7.5 s or 30 s.
2. **Hydraulic/actuator limit** — flow, head or guide-vane limits are violated.
3. **Stability screen** — the speed/frequency response is not bounded and settling.

This lets us ask a commercially useful question:

> At the present operating point, how many MW of FCR can this unit safely offer?

## Next implementation step

Replace the compact waterway with the full OpenHPL component chain:

```text
Reservoir -> HydraulicContact -> Conduit -> SurgeTank -> Penstock
          -> Turbine -> RotationalContact -> Generator -> ElectricalContact -> Grid
```

Then repeat the same 36-case screen and compare

```text
C_FCR,max(reduced model)  vs  C_FCR,max(full nonlinear OpenHPL)
```

The difference is the quantity we want to explain using water inertia, nonlinear friction, surge-tank oscillation, gate-rate saturation and transient droop.