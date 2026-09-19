"""
Air-cushion surge-tank literature prototype.

Hydraulic storage is coupled to a gas law, commonly approximated by

    p_air * V_air^gamma = constant

together with liquid volume continuity.
"""
struct AirCushionSurgeTankSpec
    liquid_area::Float64
    gas_volume0::Float64
    gas_pressure0::Float64
    polytropic_exponent::Float64
end
