"""
Francis turbine literature prototype.

Reaction-turbine family using guide-vane opening, head, speed, and discharge.

Core relations:
    Pm = rho*g*Q*H*eta
    Q  = f(H, omega, y)
    Tm = Pm/omega

A mechanistic model can additionally use Euler turbomachinery relations and
runner velocity triangles.
"""
struct FrancisTurbineSpec
    rated_head::Float64
    rated_flow::Float64
    rated_speed::Float64
end
