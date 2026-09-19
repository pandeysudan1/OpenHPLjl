"""
TurbineLookup literature prototype.

Represents a Hill-chart / characteristic-map turbine with

    Q   = f_Q(H, omega, y)
    eta = f_eta(H, omega, Q, y)
    Pm  = rho*g*Q*H*eta

Production implementation should use interpolation objects or gridded lookup
tables built from plant or manufacturer data.
"""
struct TurbineLookupSpec
    head_grid::Vector{Float64}
    speed_grid::Vector{Float64}
    gate_grid::Vector{Float64}
end
