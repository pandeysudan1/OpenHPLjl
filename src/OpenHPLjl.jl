module OpenHPLjl

using ModelingToolkit
using ModelingToolkit: t_nounits as t, D_nounits as D

include("Interfaces/HydraulicPort.jl")
include("Reservoirs/InfiniteReservoir.jl")
include("Reservoirs/Reservoir.jl")
include("Waterways/RigidPipe.jl")
include("Waterways/SurgeTank.jl")

export HydraulicPort
export InfiniteReservoir, Reservoir
export RigidPipe, SurgeTank
export project_status

"""
    project_status()

Return the current project phase.
"""
project_status() = "OpenHPLjl waterway milestone: reservoir, rigid pipe, and surge tank"

end
