"""
Kaplan turbine literature prototype.

Double-regulated reaction-turbine family using both guide-vane and runner-blade
pitch settings.

Typical characteristic maps:
    Q   = f(H, omega, y_guide, beta_blade)
    eta = f(H, Q, omega, y_guide, beta_blade)
"""
struct KaplanTurbineSpec
    rated_head::Float64
    rated_flow::Float64
    rated_speed::Float64
end
