using GISTRtree
using Test
using Extents
import ArchGDAL as AG
import GeoInterface as GI


@testset "GISTRtree.jl" begin
    x = 1:100
    y = 1:100
    points = AG.createpoint.(x, y')
    # polygons = AG.buffer.(points, 0.1)
    tree = STRtree(points)
    @test tree.rootnode isa GISTRtree.STRNode
    @test tree.rootnode.children[1] isa GISTRtree.STRNode
    
    query_result = query(tree, Extent(X=(0, 100.5), Y=(0, 1.5)))
    @test query_result isa Vector{Int}
    @test length(query_result) == 100
    @test points[query_result] == points[:,1]
end
