# SPDX-License-Identifier: MPL-2.0
# Hydraulic connector derived conceptually from OpenSimHub/OpenHPL Interfaces.Contact (MPL-2.0).

"""
    HydraulicContact(; name)

Acausal hydraulic connector. Pressure and elevation are potential variables;
mass flow is a flow variable, so connected mass flows sum to zero.
"""
@connector function HydraulicContact(; name)
    sts = @variables begin
        p(t), [description = "Hydraulic contact pressure [Pa]"]
        mdot(t), [connect = Flow, description = "Mass flow rate [kg/s]"]
        z(t), [description = "Hydraulic connection elevation [m]"]
    end
    ODESystem(Equation[], t, sts, []; name = name)
end

"""
    RotationalContact(; name)

Acausal rotational-mechanical connector for turbine, shaft and generator
components. Shaft angle and angular speed are shared potentials; torque is a
flow variable and therefore sums to zero at a connection set.
"""
@connector function RotationalContact(; name)
    sts = @variables begin
        phi(t), [description = "Shaft angle [rad]"]
        omega(t), [description = "Shaft angular speed [rad/s]"]
        tau(t), [connect = Flow, description = "Torque flowing into component [N m]"]
    end
    ODESystem(Equation[], t, sts, []; name = name)
end

"""
    ElectricalContact(; name)

Reduced electromechanical AC connector intended for active-power/frequency
studies. Voltage magnitude and voltage angle are potential variables; active
power is a flow variable. This is deliberately a reduced FCR/AGC connector,
not yet a full dq0 or phasor P-Q terminal.
"""
@connector function ElectricalContact(; name)
    sts = @variables begin
        V(t), [description = "Voltage magnitude [pu]"]
        theta(t), [description = "Electrical voltage angle [rad]"]
        P(t), [connect = Flow, description = "Active power flowing into component [pu]"]
    end
    ODESystem(Equation[], t, sts, []; name = name)
end

"""
    connect_hydraulic(a, b)

Connect two OpenHPLjl hydraulic ports. Pressure and elevation are equal across the
connection; mass flows sum to zero through ModelingToolkit's `Flow` semantics.
"""
connect_hydraulic(a, b) = connect(a, b)

"""Connect two rotational-mechanical ports."""
connect_rotational(a, b) = connect(a, b)

"""Connect two reduced electrical active-power ports."""
connect_electrical(a, b) = connect(a, b)
