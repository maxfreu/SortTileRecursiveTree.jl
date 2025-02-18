
using Test
using AbstractTrees
using SortTileRecursiveTree
using SortTileRecursiveTree: STRtree, STRNode, STRLeafNode
using Extents
using AbstractTrees: GI

@testset "AbstractTrees interface" begin
    # Create a simple test tree structure
    # Level 1: root with extent (0,0) -> (10,10)
    # Level 2: two children with extents (0,0)->(5,5) and (5,5)->(10,10)
    # Level 3: leaf nodes
    
    geom1 = GI.MultiPoint([GI.Point((0.0, 0.0)), GI.Point((2.5, 2.5))])
    geom2 = GI.MultiPoint([GI.Point((2.5, 2.5)), GI.Point((5.0, 5.0))])
    geom3 = GI.MultiPoint([GI.Point((5.0, 5.0)), GI.Point((7.5, 7.5))])
    geom4 = GI.MultiPoint([GI.Point((7.5, 7.5)), GI.Point((10.0, 10.0))])
    
    tree = STRtree([geom1, geom1, geom2, geom2, geom3, geom3, geom4, geom4]; nodecapacity=2)

    @testset "Basic Tree Structure" begin
        # Test children access
        @test length(children(tree)) == 2
        @test length(children(first(children(tree)))) == 2
        @test length(children(last(children(tree)))) == 2
        @test all(x -> isa(x, STRLeafNode), children(first(children(tree))))
        @test all(x -> isa(x, STRLeafNode), children(last(children(tree))))
    end

    @testset "Node Values" begin
        # Test that nodevalue returns proper extents
        @test nodevalue(tree) isa Extent
        @test nodevalue(first(children(tree))) isa Extent
        @test nodevalue(first(children(last(children(tree))))) isa Extent
    end

    @testset "Tree Traits" begin
        # Test ParentLinks trait
        @test ParentLinks(STRtree) == ImplicitParents()
        @test ParentLinks(STRNode) == ImplicitParents()
        @test ParentLinks(STRLeafNode) == ImplicitParents()

        # Test SiblingLinks trait
        @test SiblingLinks(STRtree) == ImplicitSiblings()
        @test SiblingLinks(STRNode) == ImplicitSiblings()
        @test SiblingLinks(STRLeafNode) == ImplicitSiblings()

        # Test ChildIndexing trait
        @test ChildIndexing(STRtree) == IndexedChildren()
        @test ChildIndexing(STRNode) == IndexedChildren()
    end

    @testset "Tree Traversal Iterators" begin
        # Test that we can traverse the tree
        nodes = collect(PreOrderDFS(tree))
        @test length(nodes) == 7  # 1 root + 2 internal nodes + 4 leaves
        
        leaves = collect(Leaves(tree))
        @test length(leaves) == 4
        @test all(x -> x isa STRLeafNode, leaves)
    end

    @testset "Node Type Stability" begin
        @test NodeType(STRtree) == NodeTypeUnknown()
        @test NodeType(STRNode) == NodeTypeUnknown()
        @test NodeType(STRLeafNode) == NodeTypeUnknown()
    end
end