module OpenHPLjl

using ModelingToolkit
using ModelingToolkit: t_nounits as t, D_nounits as D

# Interfaces first: physical potential/flow ports and causal signal ports.
include("Interfaces/HydraulicPort.jl")
include("Interfaces/RotationalPort.jl")
include("Interfaces/ElectricalPowerPort.jl")
include("Interfaces/SignalPort.jl")

# Boundary and storage components.
include("Reservoirs/InfiniteReservoir.jl")
include("Reservoirs/Reservoir.jl")

# Constitutive model registries.
include("FrictionModels/FrictionFunctions.jl")
include("FrictionModels/FrictionRegistry.jl")

# Hydraulic transport and storage.
include("Waterways/RigidPipes/RigidPipe.jl")
include("Waterways/SurgeTanks/SurgeTank.jl")

# Reusable causal sources.
include("Signals/ConstantSignal.jl")
include("Measurements/FrequencySensor.jl")
include("Controls/DroopGovernor.jl")

# Energy conversion.
include("Turbines/IdealTurbine.jl")
include("Turbines/SimpleGateTurbine.jl")
include("Turbines/ControlledGateTurbine.jl")
include("Turbines/ShaftCoupledTurbine.jl")
include("Mechanical/Shafts/LumpedShaft.jl")
include("Electrical/Generators/IdealGenerator.jl")
include("Electrical/Generators/SMIBGenerator.jl")
include("Electrical/Grids/InfiniteGrid.jl")
include("Systems/ReducedSMIB.jl")

export HydraulicPort, RotationalPort, ElectricalPowerPort
export SignalSocket, SignalPlug
export InfiniteReservoir, Reservoir
export RigidPipe, SurgeTank
export FRICTION_MODEL_REGISTRY, friction_model, available_friction_models
export no_friction, quadratic_head_loss, reynolds_number
export laminar_friction_factor, haaland_friction_factor, swamee_jain_friction_factor
export darcy_head_loss, darcy_laminar_head_loss, darcy_haaland_head_loss
export darcy_swamee_jain_head_loss, colebrook_residual
export ConstantSignal, FrequencySensor, DroopGovernor
export IdealTurbine, SimpleGateTurbine, ControlledGateTurbine, ShaftCoupledTurbine
export LumpedShaft, IdealGenerator, SMIBGenerator, InfiniteGrid
export ReducedSMIB
export project_status

"""
    project_status()

Return the current project phase.
"""
project_status() = "OpenHPLjl complete reduced MTK hydropower SMIB: hydraulics, turbine, shaft, generator, grid, measurement, governor"

end
