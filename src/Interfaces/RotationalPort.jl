"""
    RotationalPort

Acausal rotational connector.

Variables
- `omega(t)`: angular speed [rad/s], the potential/across variable.
- `tau(t)`: torque [N*m], positive into a component and marked as a flow variable.

The connector only defines connection semantics; inertia, damping and torque
conversion are component equations.
"""
@connector function RotationalPort(; name)
    vars = @variables begin
        omega(t), [guess = 2 * pi * 50, description = "Angular speed [rad/s]"]
        tau(t), [connect = Flow, guess = 0.0, description = "Torque into component [N*m]"]
    end
    return System(Equation[], t, vars, []; name = name)
end
