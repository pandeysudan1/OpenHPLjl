# SPDX-License-Identifier: MPL-2.0
# Derived conceptually from OpenSimHub/OpenHPL Interfaces.Contact (MPL-2.0).

@connector function Contact(; name)
    sts = @variables begin
        p(t), [description = "Contact pressure [Pa]"]
        mdot(t), [connect = Flow, description = "Mass flow rate [kg/s]"]
        z(t), [description = "Connection elevation [m]"]
    end
    ODESystem(Equation[], t, sts, []; name = name)
end

"""
    connect_hydraulic(a, b)

Connect two OpenHPLjl hydraulic ports. Pressure and elevation are equal across the
connection; mass flows sum to zero through ModelingToolkit's `Flow` semantics.
"""
connect_hydraulic(a, b) = connect(a, b)
