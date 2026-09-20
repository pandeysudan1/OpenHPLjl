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
@connector function HydraulicPort(; name)
    vars = @variables begin
        H(t), [guess = 0.0, description = "Hydraulic head [m]"]
        Q(t), [connect = Flow, guess = 0.0, description = "Volumetric flow into component [m^3/s]"]
    end
    return System(Equation[], t, vars, []; name = name)
end
