"""
    sine_fit(t, y, period)

Fit `y ≈ offset + a*sin(ωt) + b*cos(ωt)` using stationary Fourier
projections. This is intended for evenly sampled windows containing an integer
or near-integer number of periods.

Returns amplitude, phase, offset, fitted vector and normalized linearity index.
"""
function sine_fit(t, y, period)
    length(t) == length(y) || throw(DimensionMismatch("t and y must have equal length"))
    length(t) >= 4 || throw(ArgumentError("at least four samples are required"))
    period > 0 || throw(ArgumentError("period must be positive"))

    n = length(t)
    ω = 2 * pi / period
    offset = sum(y) / n
    yc = y .- offset

    s = sin.(ω .* t)
    c = cos.(ω .* t)

    ss = sum(s .* s)
    cc = sum(c .* c)
    sc = sum(s .* c)
    ys = sum(yc .* s)
    ycproj = sum(yc .* c)
    det = ss * cc - sc * sc
    abs(det) > eps(Float64) || throw(ArgumentError("degenerate sine-fit window"))

    a = (ys * cc - ycproj * sc) / det
    b = (ycproj * ss - ys * sc) / det
    fit = offset .+ a .* s .+ b .* c
    residual = y .- fit

    amp = hypot(a, b)
    phase = atan(b, a)
    rms_residual = sqrt(sum(abs2, residual) / n)
    fit_centered = fit .- sum(fit) / n
    σfit = sqrt(sum(abs2, fit_centered) / max(n - 1, 1))
    linearity = σfit == 0 ? Inf : rms_residual / σfit

    return (
        amplitude = amp,
        phase_rad = phase,
        phase_deg = phase * 180 / pi,
        offset = offset,
        fit = fit,
        residual = residual,
        linearity_index = linearity,
    )
end

"""
    normalized_fcr_sine_response(t, f, p; period, df_full, dp_full)

Estimate normalized FCR gain, relative phase and output linearity from a
stationary sine-test window.
"""
function normalized_fcr_sine_response(t, f, p; period, df_full, dp_full)
    abs(df_full) > 0 || throw(ArgumentError("df_full must be non-zero"))
    abs(dp_full) > 0 || throw(ArgumentError("dp_full must be non-zero"))

    ff = sine_fit(t, f, period)
    pf = sine_fit(t, p, period)

    gain = (pf.amplitude / ff.amplitude) * (abs(df_full) / abs(dp_full))
    phase = pf.phase_deg - ff.phase_deg
    while phase > 180
        phase -= 360
    end
    while phase <= -180
        phase += 360
    end

    return (
        gain = gain,
        phase_deg = phase,
        input_amplitude = ff.amplitude,
        output_amplitude = pf.amplitude,
        linearity_index = pf.linearity_index,
    )
end
