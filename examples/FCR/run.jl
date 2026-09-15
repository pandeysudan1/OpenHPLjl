println("OpenHPLjl FCR study runner")
println("Available studies are listed in examples/FCR/STUDIES.md")
println("Development execution target: Railway")

study_dirs = sort(filter(name -> isdir(joinpath(@__DIR__, name)) && occursin(r"^\\d{2}_", name), readdir(@__DIR__)))

println("Study folders:")
for name in study_dirs
    println("  - ", name)
end

println("FCR runner ready.")
