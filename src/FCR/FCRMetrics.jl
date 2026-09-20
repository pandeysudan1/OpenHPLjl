"""
    trapezoid_integral(t, y)

Dependency-free trapezoidal integral for vectors of equal length.
"""
function trapezoid_integral(t, y)
    length(t) == length(y) || throw(DimensionMismatch("t and y must have equal length"))
    length(t) >= 2 || return zero(eltype(y))
    acc = zero(promote_type(eltype(t), eltype(y)))
    @inbounds for i in 1:length(t)-1
        acc += (y[i] + y[i + 1]) * (t[i + 1] - t[i]) / 2
    end
    return acc
end

function _linear_sample(t, y, tq)
    tq <= first(t) && return first(y)
    tq >= last(t) && return last(y)
    i = searchsortedlast(t, tq)
    i == length(t) && return last(y)
    α = (tq - t[i]) / (t[i + 1] - t[i])
    return y[i] + α * (y[i + 1] - y[i])
end

"""
    fcrd_metrics(t, p; t0, p_baseline, p_ss_theoretical, t_eval=7.5,
                 initiation_fraction=0.01)

Calculate compact Nordic FCR-D screening metrics from a power time series.

Returns a NamedTuple containing:
- activated power at 7.5 s,
- P7.5/Pss ratio,
- E7.5/Pss normalized energy in seconds,
- response initiation delay,
- maximum normalized activation before and after 7.5 s.

The default 1% initiation threshold is a numerical screening convention, not
the formal definition of response initiation.
"""
function fcrd_metrics(
    t,
    p;
    t0,
    p_baseline,
    p_ss_theoretical,
    t_eval = 7.5,
    initiation_fraction = 0.01,
)
    length(t) == length(p) || throw(DimensionMismatch("t and p must have equal length"))
    abs(p_ss_theoretical) > 0 || throw(ArgumentError("p_ss_theoretical must be non-zero"))

    Δp = p .- p_baseline
    te = t0 + t_eval
    p75 = _linear_sample(t, Δp, te)

    idx = findall(x -> t0 <= x <= te, t)
    isempty(idx) && throw(ArgumentError("time vector does not cover the evaluation window"))
    tw = t[idx]
    pw = abs.(Δp[idx])
    E75 = trapezoid_integral(tw, pw)

    threshold = initiation_fraction * abs(p_ss_theoretical)
    delay = Inf
    for i in eachindex(t)
        if t[i] >= t0 && abs(Δp[i]) >= threshold
            delay = t[i] - t0
            break
        end
    end

    before = [abs(Δp[i]) for i in eachindex(t) if t0 <= t[i] <= te]
    after = [abs(Δp[i]) for i in eachindex(t) if t[i] > te]
    max_before = isempty(before) ? NaN : maximum(before) / abs(p_ss_theoretical)
    max_after = isempty(after) ? NaN : maximum(after) / abs(p_ss_theoretical)

    return (
        ΔP75 = p75,
        P75_ratio = abs(p75) / abs(p_ss_theoretical),
        E75 = E75,
        E75_ratio_s = E75 / abs(p_ss_theoretical),
        initiation_delay_s = delay,
        max_ratio_t_le_7_5 = max_before,
        max_ratio_t_gt_7_5 = max_after,
        pass_P75 = abs(p75) / abs(p_ss_theoretical) >= 0.86,
        pass_E75 = E75 / abs(p_ss_theoretical) >= 3.2,
        pass_delay = delay <= 2.5,
        pass_overshoot_early = isnan(max_before) || max_before <= 1.5,
        pass_overshoot_late = isnan(max_after) || max_after <= 1.2,
    )
end
