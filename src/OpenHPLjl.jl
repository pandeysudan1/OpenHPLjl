module OpenHPLjl

using ModelingToolkit
using ModelingToolkit: t_nounits as t, D_nounits as D

include("Interfaces/HydraulicPort.jl")
include("Reservoirs/InfiniteReservoir.jl")
include("Reservoirs/Reservoir.jl")\ninclude("FrictionModels/FrictionFunctions.jl")\ninclude("FrictionModels/FrictionRegistry.jl")
include("Waterways/RigidPipes/RigidPipe.jl")
include("Waterways/SurgeTanks/SurgeTank.jl")
include("Turbines/IdealTurbine.jl")
include("Turbines/SimpleGateTurbine.jl")

export HydraulicPort
export InfiniteReservoir, Reservoir
export RigidPipe, SurgeTank
export FRICTION_MODEL_REGISTRY, friction_model, available_friction_models
export no_friction, quadratic_head_loss, reynolds_number
export laminar_friction_factor, haaland_friction_factor, swamee_jain_friction_factor
export darcy_head_loss, darcy_laminar_head_loss, darcy_haaland_head_loss
export darcy_swamee_jain_head_loss, colebrook_residual
export IdealTurbine, SimpleGateTurbine
export project_status

"""
    project_status()

Return the current project phase.
"""
project_status() = "OpenHPLjl friction milestone: registered hydraulic loss models for waterways"

end
