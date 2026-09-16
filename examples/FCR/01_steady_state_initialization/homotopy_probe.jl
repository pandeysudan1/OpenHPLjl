using LinearAlgebra

println("FCR Study 01 — physical flow-ramp continuation probe")

Q_start = 20.0
Q_target = 55.0
rho = 1000.0
g = 9.81
mu = 1.0e-3
p_eps = 1.5e-5
h_res = 120.0
L_hr = 1200.0
D_hr = 4.0
A_hr = pi * D_hr^2 / 4
H_pen = 90.0
L_pen = 700.0
D_pen = 3.5
A_pen = pi * D_pen^2 / 4
C_v = 0.07
eta_h = 0.90
Sbase = 100e6
X_line = 0.50

function darcy_factor_local(Re, D_h, eps_r)
    Re <= 0 && return 0.0
    if Re <= 2100.0
        return 64.0 / Re
    elseif Re < 2300.0
        Re_lam, Re_tur = 2100.0, 2300.0
        X = [
            Re_lam^3 Re_lam^2 Re_lam 1.0;
            Re_tur^3 Re_tur^2 Re_tur 1.0;
            3Re_lam^2 2Re_lam 1.0 0.0;
            3Re_tur^2 2Re_tur 1.0 0.0
        ]
        Y = [
            64.0 / Re_lam,
            1.0 / (2log10(eps_r / (3.7D_h) + 5.74 / Re_tur^0.9))^2,
            -64.0 / Re_lam^2,
            -0.25 * 0.316 / Re_tur^1.25,
        ]
        K = X \ Y
        return K[1] * Re^3 + K[2] * Re^2 + K[3] * Re + K[4]
    else
        arg = eps_r / (3.7D_h) + 5.74 / (Re + eps(Float64))^0.9
        return 1.0 / (2log10(arg))^2
    end
end

function darcy_friction_local(v, D_h, L, rho, mu, eps_r)
    Re = rho * abs(v) * D_h / mu
    f = darcy_factor_local(Re, D_h, eps_r)
    return 0.5 * pi * f * rho * L * v * abs(v) * D_h / 4.0
end

function physical_operating_point(q)
    q > 0 || error("Study 01 expects positive turbine flow")

    v_hr = q / A_hr
    F_hr = darcy_friction_local(v_hr, D_hr, L_hr, rho, mu, p_eps)
    h = h_res - F_hr / (rho * g * A_hr)

    v_pen = q / A_pen
    F_pen = darcy_friction_local(v_pen, D_pen, L_pen, rho, mu, p_eps)
    dp = rho * g * (h + H_pen) - F_pen / A_pen
    dp > 0 || error("Non-positive turbine pressure drop at q=$q")

    opening = sqrt(q * abs(q) / dp) / C_v
    sin_delta = X_line * eta_h * dp * q / Sbase
    abs(sin_delta) <= 1 || error("No stable small-angle electrical equilibrium at q=$q; sin(delta)=$sin_delta")
    delta = asin(sin_delta)

    return [q, h, dp, opening, delta]
end

function physical_residual(u, q_command)
    q, h, dp, opening, delta = u
    v_hr = q / A_hr
    v_pen = q / A_pen
    F_hr = darcy_friction_local(v_hr, D_hr, L_hr, rho, mu, p_eps)
    F_pen = darcy_friction_local(v_pen, D_pen, L_pen, rho, mu, p_eps)

    return [
        (q - q_command) / Q_target,
        ((rho * g * (h_res - h)) * A_hr - F_hr) / (rho * g * h_res * A_hr),
        ((rho * g * (h + H_pen) - dp) * A_pen - F_pen) / (rho * g * (h_res + H_pen) * A_pen),
        (dp * (C_v * opening)^2 - q * abs(q)) / Q_target^2,
        eta_h * dp * q / Sbase - (1 / X_line) * sin(delta),
    ]
end

# Homotopy parameter λ has a physical meaning: it ramps the stationary flow
# command from Q_start to Q_target. Every continuation point is an exact
# equilibrium of the nonlinear hydraulic + turbine + electrical equations.
u = nothing
for i in 0:30
    λ = i / 30
    qλ = Q_start + λ * (Q_target - Q_start)
    global u = physical_operating_point(qλ)
    r = physical_residual(u, qλ)
    maxres = norm(r, Inf)
    println("FLOW_CONTINUATION_STEP λ=", round(λ; digits=4),
            " Q_m3s=", u[1],
            " h_m=", u[2],
            " dp_Pa=", u[3],
            " opening=", u[4],
            " delta_rad=", u[5],
            " maxres=", maxres)
    maxres < 1e-10 || error("Physical continuation residual failed at λ=$λ")
end

rfinal = physical_residual(u, Q_target)
maxres = norm(rfinal, Inf)
println("homotopy_u = ", u)
println("homotopy_target_residual = ", rfinal)
println("homotopy_max_residual = ", maxres)
println("homotopy_Q_m3s = ", u[1])
println("homotopy_surge_h_m = ", u[2])
println("homotopy_turbine_dp_Pa = ", u[3])
println("homotopy_opening = ", u[4])
println("homotopy_delta_rad = ", u[5])
probe_ok = all(isfinite, u) && maxres < 1e-10
println("HOMOTOPY_PROBE_OK = ", probe_ok)
probe_ok || error("Physical flow-ramp continuation probe failed")
