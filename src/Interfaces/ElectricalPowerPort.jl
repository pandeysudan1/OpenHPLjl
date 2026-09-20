"""
    ElectricalPowerPort

Reduced acausal active-power/frequency connector for electromechanical studies.

Variables
- `omega(t)`: electrical angular frequency [rad/s], potential/across variable.
- `P(t)`: active power [W], positive into a component and marked as a flow variable.

This is intentionally a reduced connector for frequency-active-power studies;
voltage, reactive power and phase-angle models belong in higher-fidelity
electrical interfaces.
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
