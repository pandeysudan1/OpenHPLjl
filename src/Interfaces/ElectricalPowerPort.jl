"""
    ElectricalPowerPort

Reduced electrical power/frequency connector for electromechanical studies.

Variables
- omega(t): electrical angular frequency [rad/s], across variable.
- P(t): active power [W], flow variable positive into a component.
"""
@connector ElectricalPowerPort begin
    omega(t), [description = "Electrical angular frequency [rad/s]"]
    P(t), [connect = Flow, description = "Active power into component [W]"]
end
