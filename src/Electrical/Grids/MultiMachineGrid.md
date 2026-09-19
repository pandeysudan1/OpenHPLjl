# Multi-machine phasor grid

Status: **planned**

Network DAE family with bus-voltage phasors and generator/load injections.

Typical formulation:
    I = Ybus * V
    S = V * conj(I)

This family should integrate with a PhasorPort and preserve sparse network
structure for larger Nordic/inter-area studies.
