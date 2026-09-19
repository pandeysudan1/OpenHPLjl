using Test
using OpenHPLjl

@testset "OpenHPLjl kickoff" begin
    @test occursin("ModelingToolkit", project_status())
end
