"""
ThrottledSurgeTank literature prototype.

Storage:
    As*dH/dt = Qin + Qout

Throttle relation:
    H_junction - H_tank = Kt*Qin*abs(Qin)

A production implementation should use a dedicated junction port so the
throttle head loss is not conflated with the tank free-surface head.
"""
struct ThrottledSurgeTankSpec
    area::Float64
    throttle_coefficient::Float64
end
