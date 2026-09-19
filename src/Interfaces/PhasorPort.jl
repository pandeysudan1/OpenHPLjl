"""
    PhasorPort

Prototype electrical phasor connector for future synchronous-machine and
network models.

Variables
- Vr(t), Vi(t): real and imaginary bus voltage components [pu]
- Ir(t), Ii(t): real and imaginary current components [pu], flow variables

This interface is not exported yet; it marks the transition from the reduced
ElectricalPowerPort to voltage/current network DAEs.
"""
@connector PhasorPort begin
    Vr(t), [description = "Real bus voltage [pu]"]
    Vi(t), [description = "Imaginary bus voltage [pu]"]
    Ir(t), [connect = Flow, description = "Real current into component [pu]"]
    Ii(t), [connect = Flow, description = "Imaginary current into component [pu]"]
end
