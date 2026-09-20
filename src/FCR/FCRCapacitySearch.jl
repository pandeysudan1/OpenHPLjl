"""
    fcr_capacity_search(candidates, evaluator)

Scan candidate FCR capacities in ascending order. `evaluator(capacity)` must
return a NamedTuple containing at least `pass::Bool`.

The result reports the largest passing candidate, the first failing candidate,
and all evaluation records. This keeps the search logic independent of a
specific plant or solver.
"""
function fcr_capacity_search(candidates, evaluator)
    isempty(candidates) && throw(ArgumentError("candidates must not be empty"))

    records = NamedTuple[]
    largest_pass = nothing
    first_fail = nothing

    for c in candidates
        result = evaluator(c)
        hasproperty(result, :pass) ||
            throw(ArgumentError("evaluator must return a NamedTuple with field :pass"))
        record = merge((capacity = c,), result)
        push!(records, record)

        if result.pass
            largest_pass = c
        elseif first_fail === nothing
            first_fail = c
            break
        end
    end

    return (
        largest_pass = largest_pass,
        first_fail = first_fail,
        records = records,
    )
end
