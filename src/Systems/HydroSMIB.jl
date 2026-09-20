"""
HydroSMIB assembly skeleton.

Intended full chain:
upper reservoir -> rigid pipe -> surge tank -> penstock ->
controlled turbine -> shaft -> classical generator -> SMIB network,
with frequency measurement and governor/servo feedback.

The hydraulic initialization and controlled turbine mechanical port are the next
promotion step. This file intentionally records the assembly architecture before
claiming a validated full hydro-SMIB simulation.
"""
struct HydroSMIBSpec
    nominal_frequency::Float64
    upper_head::Float64
    tail_head::Float64
end
