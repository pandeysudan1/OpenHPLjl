"""
    RotationalPort

Acausal rotational connector.

Variables
- `omega(t)`: angular speed [rad/s], the potential/across variable.
- `tau(t)`: torque [N*m], positive into a component and marked as a flow variable.

The connector only defines connection semantics; inertia, damping and torque
conversion are component equations.
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
