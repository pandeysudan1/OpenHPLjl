"""
Literature-guided model-family registry for OpenHPLjl.

Status:
- :baseline   implemented in v0.1.0-alpha.1
- :prototype  source model/specification added in the literature expansion
- :planned    requires additional interfaces, calibration data, or PDE machinery
"""
const MODEL_FAMILY_REGISTRY = Dict(
    :interfaces => [
        (name=:HydraulicPort, status=:baseline, family=:acausal_effort_flow),
        (name=:RotationalPort, status=:baseline, family=:acausal_effort_flow),
        (name=:ElectricalPowerPort, status=:baseline, family=:reduced_power_frequency),
        (name=:PhasorPort, status=:prototype, family=:complex_voltage_current),
    ],
    :reservoirs => [
        (name=:InfiniteReservoir, status=:baseline, family=:constant_head),
        (name=:Reservoir, status=:baseline, family=:constant_area_storage),
        (name=:NonlinearReservoir, status=:prototype, family=:area_elevation),
        (name=:ReservoirChannel, status=:planned, family=:open_channel),
    ],
    :friction => [
        (name=:QuadraticLoss, status=:baseline, family=:identified_quadratic),
        (name=:DarcyConstant, status=:baseline, family=:darcy_weisbach),
        (name=:Laminar, status=:baseline, family=:darcy_laminar),
        (name=:Haaland, status=:baseline, family=:darcy_turbulent_explicit),
        (name=:SwameeJain, status=:baseline, family=:darcy_turbulent_explicit),
        (name=:ColebrookWhite, status=:prototype, family=:darcy_turbulent_implicit),
        (name=:TransitionalFriction, status=:prototype, family=:blended_regime),
        (name=:UnsteadyFriction, status=:planned, family=:frequency_dependent),
    ],
    :rigidpipes => [
        (name=:QuasiSteadyPipe, status=:prototype, family=:algebraic_conduit),
        (name=:RigidPipe, status=:baseline, family=:rigid_water_column),
        (name=:ElasticPenstock, status=:prototype, family=:lumped_elastic),
        (name=:MOCWaterway, status=:planned, family=:method_of_characteristics),
        (name=:FiniteVolumeWaterway, status=:planned, family=:finite_volume_pde),
    ],
    :surgetanks => [
        (name=:SurgeTank, status=:baseline, family=:simple_open),
        (name=:ThrottledSurgeTank, status=:prototype, family=:throttled),
        (name=:OrificeSurgeTank, status=:prototype, family=:sharp_orifice),
        (name=:AirCushionSurgeTank, status=:prototype, family=:gas_cushion),
        (name=:VariableAreaSurgeTank, status=:prototype, family=:nonlinear_geometry),
        (name=:DifferentialSurgeTank, status=:planned, family=:multi_chamber),
    ],
    :turbines => [
        (name=:IdealTurbine, status=:baseline, family=:power_converter),
        (name=:SimpleGateTurbine, status=:baseline, family=:gate_flow),
        (name=:TurbineLookup, status=:prototype, family=:hill_chart_lookup),
        (name=:FrancisTurbine, status=:prototype, family=:reaction_turbine),
        (name=:PeltonTurbine, status=:prototype, family=:impulse_turbine),
        (name=:KaplanTurbine, status=:prototype, family=:double_regulated_reaction),
    ],
    :shafts => [
        (name=:LumpedShaft, status=:baseline, family=:single_inertia),
        (name=:TwoMassShaft, status=:prototype, family=:torsional_two_mass),
        (name=:MultiMassShaft, status=:planned, family=:torsional_multi_mass),
    ],
    :generators => [
        (name=:IdealGenerator, status=:baseline, family=:power_converter),
        (name=:ClassicalGenerator, status=:prototype, family=:second_order_swing),
        (name=:FourthOrderGenerator, status=:prototype, family=:transient_emf),
        (name=:SixthOrderGenerator, status=:planned, family=:subtransient_dq),
        (name=:SalientPoleGenerator, status=:planned, family=:salient_pole),
        (name=:RoundRotorGenerator, status=:planned, family=:round_rotor),
    ],
    :grids => [
        (name=:InfiniteGrid, status=:baseline, family=:infinite_bus),
        (name=:AggregateGrid, status=:prototype, family=:finite_inertia_frequency),
        (name=:SMIBGrid, status=:prototype, family=:power_angle),
        (name=:MultiMachineGrid, status=:planned, family=:phasor_network),
        (name=:EMTGrid, status=:planned, family=:electromagnetic_transient),
    ],
)

available_model_families() = MODEL_FAMILY_REGISTRY
