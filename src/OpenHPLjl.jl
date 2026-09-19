module OpenHPLjl

using ModelingToolkit
using ModelingToolkit: t_nounits as t, D_nounits as D

include("Interfaces/HydraulicPort.jl")
include("Reservoirs/InfiniteReservoir.jl")
include("Reservoirs/Reservoir.jl")

export HydraulicPort
export InfiniteReservoir, Reservoir
export project_status

"""
    project_status()

Return the current project phase.
"""
project_status() = "OpenHPLjl reservoir milestone: hydraulic connector and first reservoir models"

end
