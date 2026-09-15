using OpenHPLjl

println("OpenHPLjl Railway job")
println("Julia version: ", VERSION)

if get(ENV,"OPENHPL_JOB","smoke") == "fcr_compact"
    include(joinpath(@__DIR__,"..","examples","fcr_compact_study","run_study.jl"))
else
    reservoir=Reservoir(name=:reservoir)
    println("Reservoir component constructed: ",nameof(reservoir))
end
