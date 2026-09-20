"""
    HydraulicPort

Acausal hydraulic connector for OpenHPLjl.

Variables
- `H(t)`: hydraulic head [m], an across/potential variable.
- `Q(t)`: volumetric flow [m^3/s], positive into a component and marked
  `connect = Flow`, so connected flows sum to zero.
"""
function HydraulicPort(; name)
    @variables H(t), Q(t) [connect = Flow]
    return System(
        Equation[],
        t,
        [H, Q],
        [];
        name,
        connector_type = ModelingToolkit.RegularConnector(),
    )
end
