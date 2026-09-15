# FCR Studies

This folder is the canonical workspace for frequency-containment-reserve studies built with the full component model in OpenHPLjl.

## Study sequence

1. **01_steady_state_initialization** — assemble reservoir, waterways, surge tank, penstock, turbine, shaft, synchronous generator, line and grid; verify a consistent steady operating point.
2. **02_open_loop_load_step** — apply a load disturbance with governor action disabled and quantify the natural inertial and hydraulic response.
3. **03_primary_droop_fcr** — close the frequency-to-governor-to-guide-vane loop and study ordinary droop response.
4. **04_transient_droop_fcr** — use the OpenHPL transient-droop governor and compare against ordinary droop.
5. **05_rate_limit_and_saturation** — study guide-vane opening/closing rate limits and actuator saturation during FCR activation.
6. **06_waterway_dynamics** — quantify the influence of penstock inertia, friction, surge-tank oscillation and water starting time on frequency response.
7. **07_operating_point_sweep** — repeat the FCR event over loading/head/guide-vane operating points and compare nonlinear responses.
8. **08_disturbance_size_sweep** — vary the active-power imbalance and identify the range where linearized approximations stop representing the nonlinear plant well.
9. **09_fcr_prequalification_metrics** — calculate response time, delivered power, frequency nadir, settling behaviour and other metrics relevant to Statnett-style FCR assessment.
10. **10_model_linearization** — linearize the assembled nonlinear ModelingToolkit model around selected operating points and compare time-domain, Bode and Nyquist behaviour.
11. **11_multi_unit_isochronous_droop** — extend to multiple hydro units and compare isochronous and droop sharing.
12. **12_agc_secondary_control** — add secondary frequency control/AGC above the primary FCR loop.
13. **13_two_area_tieline_agc** — extend AGC to interconnected areas with tie-line power and area-control-error dynamics.

## Execution policy

Railway is the fast compute runner for development studies. GitHub Actions is retained as the slower final regression/compatibility gate.

Each study should eventually contain:

- `run.jl` — executable simulation
- `README.md` — problem, equations, parameters, results and interpretation
- `results/` — generated CSV/SVG/PNG outputs when worth keeping

The studies should reuse package components from `src/` rather than duplicate physical equations inside the examples.
