"""
    ElectricalPowerPort

Reduced electrical power/frequency connector for electromechanical studies.

Variables
- omega(t): electrical angular frequency [rad/s], across variable.
- P(t): active power [W], flow variable positive into a component.
"""
function ElectricalPowerPort(; name)
    @variables omega(t), P(t) [connect = Flow]
    return System(
        Equation[],
        t,
        [omega, P],
        [];
        name,
        connector_type = ModelingToolkit.RegularConnector(),
    )
end
