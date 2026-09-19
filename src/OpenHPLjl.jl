module OpenHPLjl

using ModelingToolkit
using ModelingToolkit: t_nounits as t, D_nounits as D

include("Interfaces/HydraulicPort.jl")
include("Reservoirs/InfiniteReservoir.jl")
include("Reservoirs/Reservoir.jl")
include("Waterways/RigidPipe.jl")

export HydraulicPort
export InfiniteReservoir, Reservoir
export RigidPipe
export project_status

"""
    project_status()

Return the current project phase.
"""
project_status() = "OpenHPLjl rigid-pipe milestone: reservoir storage plus waterway momentum"

end
