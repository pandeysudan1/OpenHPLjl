module OpenHPLjl

using ModelingToolkit
using ModelingToolkit: t_nounits as t, D_nounits as D

include("Interfaces/HydraulicPort.jl")
include("Interfaces/RotationalPort.jl")
include("Interfaces/ElectricalPowerPort.jl")
include("Interfaces/PhasorPort.jl")
include("Interfaces/SignalPort.jl")
include("Reservoirs/InfiniteReservoir.jl")
include("Reservoirs/Reservoir.jl")
include("Reservoirs/NonlinearReservoir.jl")
include("FrictionModels/FrictionFunctions.jl")
include("FrictionModels/FrictionRegistry.jl")
include("FrictionModels/TransitionalFriction.jl")
include("Waterways/RigidPipes/RigidPipe.jl")
include("Waterways/RigidPipes/QuasiSteadyPipe.jl")
include("Waterways/SurgeTanks/SurgeTank.jl")
include("Turbines/IdealTurbine.jl")
include("Turbines/SimpleGateTurbine.jl")
include("Measurements/FrequencySensor.jl")
include("Measurements/PowerMeasurement.jl")
include("Controls/DroopGovernor.jl")
include("Controls/GateServo.jl")
include("Controls/PIController.jl")
include("Controls/MechanicalTorqueActuator.jl")
include("Mechanical/Shafts/LumpedShaft.jl")
include("Mechanical/Shafts/TwoMassShaft.jl")
include("Electrical/Generators/IdealGenerator.jl")
include("Electrical/Generators/ClassicalGeneratorRotor.jl")
include("Electrical/Grids/InfiniteGrid.jl")
include("Electrical/Grids/SMIBNetwork.jl")
include("ModelFamilies/ModelFamilyRegistry.jl")
include("Systems/ReducedSMIB.jl")
include("Systems/HydroSMIB.jl")

export HydraulicPort, RotationalPort, ElectricalPowerPort, PhasorPort, SignalPort
export InfiniteReservoir, Reservoir, NonlinearReservoir
export RigidPipe, QuasiSteadyPipe, SurgeTank
export FRICTION_MODEL_REGISTRY, friction_model, available_friction_models
export no_friction, quadratic_head_loss, reynolds_number
export laminar_friction_factor, haaland_friction_factor, swamee_jain_friction_factor
export darcy_head_loss, darcy_laminar_head_loss, darcy_haaland_head_loss
export darcy_swamee_jain_head_loss, colebrook_residual
export IdealTurbine, SimpleGateTurbine
export FrequencySensor, PowerMeasurement
export DroopGovernor, GateServo, PIController, MechanicalTorqueActuator
export LumpedShaft, TwoMassShaft, IdealGenerator, ClassicalGeneratorRotor, InfiniteGrid, SMIBNetwork
export MODEL_FAMILY_REGISTRY, available_model_families
export ReducedSMIB, HydroSMIBSpec
export blended_friction_factor
export project_status

"""
    project_status()

Return the current project phase.
"""
project_status() = "OpenHPLjl SMIB milestone: measurement, governor, servo, and reduced closed-loop SMIB"

end
