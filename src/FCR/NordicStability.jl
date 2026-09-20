"""
    nordic_open_loop(F, G)

Combine the normalized FCR-providing-entity response `F(jω)` and an externally
supplied Nordic power-system response `G(jω)` using

    G0(jω) = -F(jω)G(jω).

The official Nordic system-model data must be supplied by the caller. This
package deliberately does not embed undocumented coefficients.
"""
nordic_open_loop(F, G) = .-(F .* G)

"""
    nyquist_screen(G0; radius=0.43)

Return the minimum distance of an open-loop complex response to (-1, 0j) and
whether all supplied points remain outside the screening circle.
"""
function nyquist_screen(G0; radius = 0.43)
    isempty(G0) && throw(ArgumentError("G0 must contain at least one point"))
    d = abs.(G0 .+ 1)
    i = argmin(d)
    return (
        min_distance = d[i],
        critical_index = i,
        critical_point = G0[i],
        radius = radius,
        pass = d[i] >= radius,
    )
end
