using OpenHPLjl

println("OpenHPLjl service started")
println("Julia version: ", VERSION)

# Construct the first translated component as a deployment smoke test.
reservoir = Reservoir(name = :reservoir)
println("Reservoir component constructed: ", nameof(reservoir))

# Keep the Railway worker alive. Model translation/validation jobs can be added here
# or moved to dedicated scripts as the package grows.
wait(Condition())
