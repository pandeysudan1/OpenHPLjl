"""
Registry of friction/head-loss functions.

Use friction_model(:quadratic) or another registered symbol to retrieve a
build-time function for a waterway component.
"""
const FRICTION_MODEL_REGISTRY = Dict{Symbol, Function}(
    :none => no_friction,
    :quadratic => quadratic_head_loss,
    :darcy_constant => darcy_head_loss,
    :darcy_laminar => darcy_laminar_head_loss,
    :darcy_haaland => darcy_haaland_head_loss,
    :darcy_swamee_jain => darcy_swamee_jain_head_loss,
)

available_friction_models() = sort!(collect(keys(FRICTION_MODEL_REGISTRY)))

function friction_model(name::Symbol)
    haskey(FRICTION_MODEL_REGISTRY, name) ||
        throw(ArgumentError("Unknown friction model $(name). Available: $(available_friction_models())"))
    return FRICTION_MODEL_REGISTRY[name]
end
