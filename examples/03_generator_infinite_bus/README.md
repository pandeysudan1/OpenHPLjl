# Component-wise generator to infinite bus

## Problem

Before adding the full nonlinear waterway and AGC, the new acausal mechanical and electrical interfaces need to be validated in the smallest useful system.

```text
Mechanical power source
        |
        | RotationalContact
        v
Classical synchronous generator
        |
        | ElectricalContact
        v
Lossless transmission line
        |
        v
Infinite bus, 50 Hz
```

The machine starts from an electrical equilibrium at `P = 0.80 pu`. At `t = 5 s`, mechanical input power is increased to `0.88 pu`.

## Components

The shaft connection carries

```text
phi, omega, tau
```

with torque as the acausal flow variable.

The electrical connection carries

```text
V, theta, P
```

with active power as the acausal flow variable.

The generator rotor obeys

```text
J domega/dt = tau_m - tau_e - damping
```

and the rotor electrical angle evolves as

```text
ddelta/dt = pole_pairs (omega - omega_sync)
```

The lossless line uses

```text
P = V1 V2 / X * sin(theta1 - theta2)
```

## Why this example exists

This example is not the final FCR study. It proves that torque can cross a rotational connector and electrical power can cross an electrical connector without directly wiring turbine power into a frequency equation.

Once this case is green, the mechanical power source will be replaced by

```text
Reservoir -> Headrace -> SurgeTank -> Penstock -> Turbine
```

and the turbine will drive the same generator through `RotationalContact`. Governor, isochronous control and AGC will then act on the hydraulic turbine rather than on a reduced grid equation.

## Run

```bash
julia --project=. examples/03_generator_infinite_bus/component_smib.jl
```
