"""
    RotationalPort

Acausal rotational connector.

Variables
- omega(t): angular speed [rad/s], across variable.
- tau(t): torque [N*m], flow variable positive into a component.
"""
@connector RotationalPort begin
    omega(t), [description = "Angular speed [rad/s]"]
    tau(t), [connect = Flow, description = "Torque into component [N*m]"]
end
