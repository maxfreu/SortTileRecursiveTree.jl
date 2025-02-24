using SortTileRecursiveTree
using Test
using Extents
import ArchGDAL as AG
import GeoInterface as GI


@testset "SortTileRecursiveTree.jl" begin
    @testset "Single point" begin
        point = AG.createpoint(1, 1)
        tree = STRtree([point])

        # test that showing the thing works
        display(tree)

        @test query(tree, Extent(X=(0, 1.5), Y=(0, 1.5))) == [1]
        @test query(tree, Extent(X=(0, 0.5), Y=(0, 0.5))) == []
        @test_throws ArgumentError query(tree, 1)
    end
    
    @testset "Many points" begin
        x = 1:100
        y = 1:100
        points = AG.createpoint.(x, y')
        # polygons = AG.buffer.(points, 0.1)
        tree = STRtree(points)
        display(tree)
        
        @test tree.rootnode isa SortTileRecursiveTree.STRNode
        @test tree.rootnode.children[1] isa SortTileRecursiveTree.STRNode
        
        query_result = query(tree, Extent(X=(0, 100.5), Y=(0, 1.5)))
        @test query_result isa Vector{Int}
        @test length(query_result) == 100
        @test points[query_result] == points[:,1]
        @test query(tree, Extent(X=(0, 0.5), Y=(0, 0.5))) == []
    end
    @testset "AbstractTrees interface" begin; include("abstracttrees.jl"); end
end
