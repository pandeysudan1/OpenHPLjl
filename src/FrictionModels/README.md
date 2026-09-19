# Friction model family

The friction layer is separated from waterway components so the same RigidPipe
momentum equation can be reused with different loss laws.

Registered head-loss models:

- :none — zero loss.
- :quadratic — compact hydropower law h_f = R Q |Q|.
- :darcy_constant — Darcy-Weisbach with prescribed Darcy factor f.
- :darcy_laminar — Darcy-Weisbach with f = 64/Re.
- :darcy_haaland — explicit turbulent Darcy factor from Haaland.
- :darcy_swamee_jain — explicit turbulent Darcy factor from Swamee-Jain.

The implicit Colebrook-White relation is provided as colebrook_residual for
later use with NonlinearSolve.jl.

The registry is intentionally build-time: a pipe selects a friction law when
the ModelingToolkit system is constructed, avoiding a symbolic branch inside
the DAE.
