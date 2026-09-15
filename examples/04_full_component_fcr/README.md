# Full nonlinear hydro FCR study

## Problem

Build one component-wise hydropower model from reservoir to grid and use it for a primary-frequency-control study.

```text
Constant-level reservoir
        |
     Headrace
        |
    Surge tank
        |
     Penstock
        |
Hydro turbine + shaft
        |
 RotationalContact
        |
Synchronous generator
        |
 ElectricalContact
        |
   Lossless line
        |
 Single-area grid
        ^
        |
     Governor
```

The plant starts near an 8 MW operating point on a 10 MW base. At `t = 5 s`, grid load increases by 10%:

```text
0.80 pu -> 0.88 pu
```

The study asks whether the governor can increase guide-vane opening and turbine power fast enough to arrest the frequency drop while the nonlinear waterway and surge tank remain stable.

## Solution

The hydraulic components use OpenHPL-style nonlinear equations.

Pipe momentum:

```text
L d(mdot)/dt = (p_i + rho g H - p_o) A - F_f
```

Surge tank:

```text
dm/dt = mdot_in + mdot_out

dM/dt = mdot v + F_p - F_f - F_g
```

Turbine valve law:

```text
dp (C_v u^alpha)^2 = Q |Q|
```

Hydraulic power is converted to shaft torque:

```text
P_t = eta dp Q

tau_t = P_t / omega
```

The turbine and generator are connected only through `RotationalContact`.

The generator and grid are connected only through `ElectricalContact` and a lossless line:

```text
P = V1 V2 / X * sin(theta1 - theta2)
```

The grid area has finite inertia:

```text
2H d(omega)/dt = P_in - P_load - D(omega - 1)
```

and the governor uses grid frequency:

```text
u_cmd = clamp(u0 + (f_ref - f)/(R f_ref))
T_g du/dt = u_cmd - u
```

The expected sequence after the load step is:

```text
load rises
-> grid frequency falls
-> governor opens guide vane
-> turbine flow and torque increase
-> generator electrical power increases
-> frequency decline is arrested
```

## Why this example matters

This is the base architecture for the next studies:

```text
1. droop FCR
2. OpenHPL transient-droop FCR
3. isochronous control
4. single-area AGC
5. multiple generators with participation factors
6. two-area AGC with tie-line control
```

The main point is that those studies can now reuse the same physical component interfaces instead of rewriting the plant equations.

## Run

```bash
julia --project=. examples/04_full_component_fcr/full_component_fcr.jl
```
