using LinearAlgebra

println("FCR Study 01 — lightweight homotopy operating-point probe")

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

h_seed = 105.0
dp_seed = 1.70e6
u_seed = 0.65
delta_seed = 0.40
u = [Q_target, h_seed, dp_seed, u_seed, delta_seed]

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

function residual(u, λ)
    q, h, dp, opening, delta = u
    v_hr = q / A_hr
    v_pen = q / A_pen
    F_hr = darcy_friction_local(v_hr, D_hr, L_hr, rho, mu, p_eps)
    F_pen = darcy_friction_local(v_pen, D_pen, L_pen, rho, mu, p_eps)

    actual = [
        (q - Q_target) / Q_target,
        ((rho * g * (h_res - h)) * A_hr - F_hr) / (rho * g * h_res * A_hr),
        ((rho * g * (h + H_pen) - dp) * A_pen - F_pen) / (rho * g * (h_seed + H_pen) * A_pen),
        (dp * (C_v * opening)^2 - q * abs(q)) / Q_target^2,
        eta_h * dp * q / Sbase - (1 / X_line) * sin(delta),
    ]

    simple = [
        (q - Q_target) / Q_target,
        (h - h_seed) / h_res,
        (dp - dp_seed) / dp_seed,
        opening - u_seed,
        delta - delta_seed,
    ]
    return (1 - λ) .* simple .+ λ .* actual
end

function fd_jacobian(f, x, λ)
    r0 = f(x, λ)
    J = zeros(length(r0), length(x))
    for j in eachindex(x)
        dx = sqrt(eps(Float64)) * max(abs(x[j]), 1.0)
        xp = copy(x)
        xp[j] += dx
        J[:, j] .= (f(xp, λ) .- r0) ./ dx
    end
    return J
end

function newton_at_lambda(u0, λ; tol=1e-11, maxiter=30)
    x = copy(u0)
    for k in 1:maxiter
        r = residual(x, λ)
        nr = norm(r, Inf)
        nr < tol && return x, true, k, nr
        J = fd_jacobian(residual, x, λ)
        step = -(J \ r)
        α = 1.0
        accepted = false
        while α >= 1 / 4096
            xt = x .+ α .* step
            if all(isfinite, xt) && norm(residual(xt, λ), Inf) < nr
                x = xt
                accepted = true
                break
            end
            α *= 0.5
        end
        accepted || return x, false, k, nr
    end
    r = residual(x, λ)
    return x, norm(r, Inf) < tol, maxiter, norm(r, Inf)
end

# Adaptive continuation: increase λ when Newton is easy, halve the step when
# the nonlinear branch becomes difficult. This follows the solution path rather
# than forcing a fixed Δλ through a turning/high-curvature region.
λ = 0.0
Δλ = 1 / 30
Δλ_min = 1e-5
Δλ_max = 0.05
step_id = 0
while λ < 1.0 - 1e-14
    λ_trial = min(1.0, λ + Δλ)
    u_trial, ok, iters, nr = newton_at_lambda(u, λ_trial)
    step_id += 1
    println("HOMOTOPY_STEP id=", step_id,
            " λ_from=", round(λ; digits=6),
            " λ_to=", round(λ_trial; digits=6),
            " Δλ=", Δλ,
            " ok=", ok,
            " iterations=", iters,
            " maxres=", nr)

    if ok
        global u = u_trial
        global λ = λ_trial
        if iters <= 4
            global Δλ = min(Δλ_max, 1.35 * Δλ)
        elseif iters >= 8
            global Δλ = max(Δλ_min, 0.7 * Δλ)
        end
    else
        global Δλ *= 0.5
        Δλ >= Δλ_min || error("Adaptive homotopy step became too small near λ=$λ; last residual=$nr")
    end
end

rfinal = residual(u, 1.0)
maxres = norm(rfinal, Inf)
println("homotopy_u = ", u)
println("homotopy_target_residual = ", rfinal)
println("homotopy_max_residual = ", maxres)
println("homotopy_Q_m3s = ", u[1])
println("homotopy_surge_h_m = ", u[2])
println("homotopy_turbine_dp_Pa = ", u[3])
println("homotopy_opening = ", u[4])
println("homotopy_delta_rad = ", u[5])
probe_ok = all(isfinite, u) && maxres < 1e-8
println("HOMOTOPY_PROBE_OK = ", probe_ok)
probe_ok || error("Lightweight homotopy probe failed")
