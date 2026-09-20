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
@connector function ElectricalPowerPort(; name)
    vars = @variables begin
        omega(t), [guess = 2 * pi * 50, description = "Electrical angular frequency [rad/s]"]
        P(t), [connect = Flow, guess = 0.0, description = "Active power into component [W]"]
    end
    return System(Equation[], t, vars, []; name = name)
end
