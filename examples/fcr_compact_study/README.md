# Compact FCR study

This reduced hydro-unit study screens controller settings before the full nonlinear waterway DAE is used. It is small enough to run as a one-off Railway job and adds no plotting dependency.

## Cases

1. Standard droop versus the OpenHPL-style transient-droop controller for a 10% load increase at 5 s.
2. A six-case sweep of droop and governor/transient time constants.
3. Frequency nadir, time to nadir, maximum activation, and delivered power after 5, 15, and 30 seconds.

The grid balance is `2H d(Δω)/dt = ΔP_m - ΔP_L - D Δω`. The reduced waterway is `T_w d(ΔP_m)/dt = ΔY - ΔP_m`.

Run with:

```bash
julia --project=. examples/fcr_compact_study/run_study.jl
```

It writes `timeseries.csv`, `metrics.csv`, `parameter_sweep.csv`, `frequency_comparison.svg`, and `power_comparison.svg` under `results/`.

The 5/15/30-second values are engineering screening metrics, not an official Statnett prequalification verdict. A formal test must use the current product-specific activation profile, measurement rules, tolerances, baseline method, and documentation requirements.
