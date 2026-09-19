"""
    HydraulicPort

Acausal hydraulic connector for OpenHPLjl.

Variables
- `H(t)`: hydraulic head [m], an across/potential variable.
- `Q(t)`: volumetric flow [m^3/s], positive into a component and marked
  `connect = Flow`, so connected flows sum to zero.
"""
@connector HydraulicPort begin
    H(t), [description = "Hydraulic head [m]"]
    Q(t), [connect = Flow, description = "Volumetric flow into component [m^3/s]"]
end
