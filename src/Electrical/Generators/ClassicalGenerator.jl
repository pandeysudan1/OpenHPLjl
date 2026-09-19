"""
ClassicalGenerator literature prototype.

Second-order swing-equation family:

    ddelta/dt = omega - omega_s
    M*domega/dt = Pm - Pe - D*(omega-omega_s)

A complete implementation needs a power-angle/network relation for Pe and a
mechanical power/torque interface. The current reduced ElectricalPowerPort does
not yet carry voltage angle, so this file records the model equations and state
set without exporting the component.
"""
struct ClassicalGeneratorSpec
    M::Float64
    D::Float64
    omega_s::Float64
end
