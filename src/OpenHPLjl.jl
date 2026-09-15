# SPDX-License-Identifier: MPL-2.0
module OpenHPLjl

using ModelingToolkit

@independent_variables t
const D = Differential(t)

include("Interfaces.jl")
include("Functions.jl")
include("Waterway.jl")
include("Mechanics.jl")
include("Electrical.jl")
include("Turbomachinery.jl")
include("ElectroMech.jl")

export t, D
export Contact, RotationalContact, ElectricalContact
export connect_hydraulic, connect_rotational, connect_electrical
export darcy_factor, darcy_friction
export Reservoir, HydroPipe, SurgeTank, PressureBoundary
export PowerToTorque, RigidShaft
export ClassicalSynchronousGenerator, LosslessLine, InfiniteBus, SingleAreaGrid
export HydroTurbineShaft
export Turbine, SimpleGenerator, SMIBGenerator, DroopGovernor, OpenHPLGovernor

end # module
