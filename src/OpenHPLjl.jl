module OpenHPLjl

using ModelingToolkit
using ModelingToolkit: t_nounits as t, D_nounits as D

include("Interfaces/HydraulicPort.jl")
include("Reservoirs/InfiniteReservoir.jl")
include("Reservoirs/Reservoir.jl")
include("Waterways/RigidPipes/RigidPipe.jl")
include("Waterways/SurgeTanks/SurgeTank.jl")
include("Turbines/IdealTurbine.jl")
include("Turbines/SimpleGateTurbine.jl")

export HydraulicPort
export InfiniteReservoir, Reservoir
export RigidPipe, SurgeTank
export IdealTurbine, SimpleGateTurbine
export project_status

"""
    project_status()

Return the current project phase.
"""
project_status() = "OpenHPLjl turbine milestone: modular waterways and first turbine model family"

end
