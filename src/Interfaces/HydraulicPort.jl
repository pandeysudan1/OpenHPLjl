"""
    HydraulicPort

Acausal hydraulic connector.

Variables
- `H(t)`: hydraulic head [m], the potential/across variable.
- `Q(t)`: volumetric flow [m^3/s], positive into a component and marked
  `connect = Flow`; connected flows therefore sum to zero.

The connector contains no constitutive physics. Conservation and constitutive
relations belong to the components that use the port.
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
