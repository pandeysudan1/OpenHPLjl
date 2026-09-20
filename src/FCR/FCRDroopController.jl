"""
    FCRDroopController(; name, product=:FCRDUp, f0=50.0, y0=1.0,
                        gate_range=0.15, Tg=0.2)

Compact product-oriented FCR controller for test and tutorial use.

Activation laws:
- `:FCRN`: linear from +1 at 49.9 Hz to -1 at 50.1 Hz.
- `:FCRDUp`: 0 at 49.9 Hz and above, +1 at 49.5 Hz and below.
- `:FCRDDown`: 0 at 50.1 Hz and below, -1 at 50.5 Hz and above.

The activation is converted to guide-vane command by
`y_cmd = y0 + gate_range * activation`, followed by a first-order lag.

This component is a screening controller, not a substitute for the provider's
actual governor implementation.
"""
@component function FCRDroopController(;
    name,
    product = :FCRDUp,
    f0 = 50.0,
    y0 = 1.0,
    gate_range = 0.15,
    Tg = 0.2,
)
    product in (:FCRN, :FCRDUp, :FCRDDown) ||
        throw(ArgumentError("product must be :FCRN, :FCRDUp, or :FCRDDown"))

    @named f_meas = SignalSocket()
    @named gate = SignalPlug()

    @parameters begin
        f0 = f0
        y0 = y0
        gate_range = gate_range
        Tg = Tg
    end

    @variables begin
        activation(t) = 0.0, [description = "Normalized FCR activation [-]"]
        y_cmd(t) = y0, [description = "Guide-vane target [-]"]
        y(t) = y0, [description = "Guide-vane command [-]"]
    end

    aexpr = if product == :FCRN
        ifelse(
            f_meas.u <= 49.9,
            1.0,
            ifelse(f_meas.u >= 50.1, -1.0, (f0 - f_meas.u) / 0.1),
        )
    elseif product == :FCRDUp
        ifelse(
            f_meas.u >= 49.9,
            0.0,
            ifelse(f_meas.u <= 49.5, 1.0, (49.9 - f_meas.u) / 0.4),
        )
    else
        ifelse(
            f_meas.u <= 50.1,
            0.0,
            ifelse(f_meas.u >= 50.5, -1.0, -(f_meas.u - 50.1) / 0.4),
        )
    end

    eqs = [
        activation ~ aexpr
        y_cmd ~ y0 + gate_range * activation
        Tg * D(y) ~ y_cmd - y
        gate.u ~ y
    ]

    return System(
        eqs,
        t,
        [activation, y_cmd, y],
        [f0, y0, gate_range, Tg];
        systems = [f_meas, gate],
        name = name,
    )
end
