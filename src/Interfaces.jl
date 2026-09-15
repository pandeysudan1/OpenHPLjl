# SPDX-License-Identifier: MPL-2.0
# Connector concepts derived from OpenSimHub/OpenHPL interfaces where applicable.

"""
    HydraulicContact(; name)

Minimal acausal hydraulic connector for incompressible waterway models.
Pressure is the across variable and mass flow is the flow variable.
Elevation is component geometry, not a connection potential, and is therefore
kept out of the connector.
"""
@connector function HydraulicContact(; name)
    sts = @variables begin
        p(t), [description = "Hydraulic pressure [Pa]"]
        mdot(t), [connect = Flow, description = "Mass flow rate [kg/s]"]
    end
    ODESystem(Equation[], t, sts, []; name = name)
end

"""
    RotationalContact(; name)

Minimal acausal rotational-mechanical connector. Angular speed is the shared
across variable and torque is the flow variable. Absolute shaft angle is not
required at the interface for the present turbine-generator models; rotor angle
is maintained internally by the generator electrical model.
"""
@connector function RotationalContact(; name)
    sts = @variables begin
        omega(t), [description = "Shaft angular speed [rad/s]"]
        tau(t), [connect = Flow, description = "Torque flowing into component [N m]"]
    end
    ODESystem(Equation[], t, sts, []; name = name)
end

"""
    ElectricalContact(; name)

Minimal acausal reduced active-power connector for FCR/AGC studies.
Electrical angle is the across variable and active power is the flow variable.
Voltage magnitude is intentionally kept as a component/line parameter in this
reduced model. A future full AC connector should use a balanced P-Q terminal
rather than adding voltage magnitude without a corresponding reactive-power flow.
"""
@connector function ElectricalContact(; name)
    sts = @variables begin
        theta(t), [description = "Electrical voltage angle [rad]"]
        P(t), [connect = Flow, description = "Active power flowing into component [pu]"]
    end
    ODESystem(Equation[], t, sts, []; name = name)
end

"""Connect two hydraulic ports."""
connect_hydraulic(a, b) = connect(a, b)

"""Connect two rotational-mechanical ports."""
connect_rotational(a, b) = connect(a, b)

"""Connect two reduced electrical active-power ports."""
connect_electrical(a, b) = connect(a, b)
