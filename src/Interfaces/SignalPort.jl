"""
    SignalPort

Scalar acausal signal connector used for measurements, set-points, and control
commands. No Flow variable: connected values are equal.
"""
@connector SignalPort begin
    u(t), [description = "Scalar signal"]
end
