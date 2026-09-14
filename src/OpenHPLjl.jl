# SPDX-License-Identifier: MPL-2.0
module OpenHPLjl

using ModelingToolkit

@independent_variables t
const D = Differential(t)

include("Interfaces.jl")
include("Functions.jl")
include("Waterway.jl")

export t, D
export Contact, connect_hydraulic
export darcy_factor, darcy_friction
export Reservoir, Pipe, PressureBoundary

end # module
