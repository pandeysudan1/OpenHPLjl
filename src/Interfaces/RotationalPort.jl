"""
    RotationalPort

Acausal rotational connector.

Variables
- omega(t): angular speed [rad/s], across variable.
- tau(t): torque [N*m], flow variable positive into a component.
"""
function RotationalPort(; name)
    @variables omega(t), tau(t) [connect = Flow]
    return System(
        Equation[],
        t,
        [omega, tau],
        [];
        name,
        connector_type = ModelingToolkit.RegularConnector(),
    )
end
