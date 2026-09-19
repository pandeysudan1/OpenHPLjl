"""
Pelton turbine literature prototype.

Impulse-turbine family based on nozzle/jet flow and bucket momentum exchange.

Typical reduced relations:
    Q = Cd*Ajet*sqrt(2*g*H)
    Pm = eta*rho*g*Q*H

Needle/nozzle servo dynamics can be added as a separate control component.
"""
struct PeltonTurbineSpec
    jet_area::Float64
    discharge_coefficient::Float64
    efficiency::Float64
end
