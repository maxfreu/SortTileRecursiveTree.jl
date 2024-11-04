module SortTileRecursiveTree

using Extents
import GeoInterface as GI
import AbstractTrees


"""
    STRtree(geoms; nodecapacity=10)

Construct an STRtree from a collection of geometries with the given node capacity.
"""
struct STRtree{T}
    rootnode::T
    function STRtree(geoms; nodecapacity=10)
        rootnode = build_root_node(geoms, nodecapacity=nodecapacity)
        return new{typeof(rootnode)}(rootnode)
    end
end


struct STRNode{E,T}
    extent::E
    children::T
end


struct STRLeafNode{E}
    extents::E
    indices::Vector{Int}
end


GI.extent(n::STRNode) = n.extent
GI.extent(n::STRLeafNode) = foldl(Extents.union, n.extents)


function Base.show(io::IO, tree::SortTileRecursiveTree.STRtree)
    println(io, "STRtree")
    if tree.rootnode isa STRNode
        display(tree.rootnode.extent)
    elseif tree.rootnode isa STRLeafNode
        display(foldl(Extents.union, tree.rootnode.extents))
    end
end


function leafnodes(geoms; nodecapacity=10)
    extents_indices = [(GI.extent(geoms[i]), i) for i in eachindex(geoms)]
    perm = sortperm(extents_indices; by=(v -> ((v[1][1][1] + v[1][1][2]) / 2)))  # [extent/index][dim][min/max] sort by x
    sorted_extents = extents_indices[perm]
    r = length(sorted_extents)
    P = ceil(Int, r / nodecapacity)
    S = ceil(Int, sqrt(P))
    x_splits = Iterators.partition(sorted_extents, S * nodecapacity)
    
    nodes = STRLeafNode{Vector{typeof(extents_indices[1][1])}}[]
    for x_split in x_splits
        perm = sortperm(x_split; by=(v -> ((v[1][2][1] + v[1][2][2]) / 2)))  # [extent/index][dim][min/max] sort by y
        sorted_split = x_split[perm]
        y_splits = Iterators.partition(sorted_split, nodecapacity)
        for y_split in y_splits
            push!(nodes, STRLeafNode(getindex.(y_split,1), getindex.(y_split,2)))
        end
    end
    return nodes
end


# a bit of duplication...
function parentnodes(nodes; nodecapacity=10)
    extents_indices = [(GI.extent(node), node) for node in nodes]
    perm = sortperm(extents_indices; by=(v -> ((v[1][1][1] + v[1][1][2]) / 2)))  # [extent/node][dim][min/max] sort by x
    sorted_extents = extents_indices[perm]
    r = length(sorted_extents)
    P = ceil(Int, r / nodecapacity)
    S = ceil(Int, sqrt(P))
    x_splits = Iterators.partition(sorted_extents, S * nodecapacity)
    
    T = typeof(extents_indices[1][1])
    N = Vector{typeof(extents_indices[1][2])}
    nodes = STRNode{T, N}[]
    for x_split in x_splits
        perm = sortperm(x_split; by=(v -> ((v[1][2][1] + v[1][2][2]) / 2)))  # [extent/index][dim][min/max] sort by y
        sorted_split = x_split[perm]
        y_splits = Iterators.partition(sorted_split, nodecapacity)
        for y_split in y_splits
            push!(nodes, STRNode(foldl(Extents.union, getindex.(y_split,1)), getindex.(y_split,2)))
        end
    end
    return nodes
end


"""recursively build root node from geometries and node capacity"""
function build_root_node(geoms; nodecapacity=10)
    nodes = leafnodes(geoms, nodecapacity=nodecapacity)
    while length(nodes) > 1
        nodes = parentnodes(nodes, nodecapacity=nodecapacity)
    end
    return nodes[1]
end


"""
    query(tree::STRtree, extent::Extent)
    query(tree::STRtree, geom)

Query the tree for geometries whose extent intersects with the given extent or the extent of the given geometry.
Returns a vector of indices of the geometries that can be used to index into the original collection of geometries under the assumption that the collection has not been modified since the tree was built.
"""
function query end

function query(tree::STRtree, extent::Extent)
    query_result = Int[]
    query!(query_result, tree.rootnode, extent)
    return unique(sort!(query_result))
end

query(tree::STRtree, geom) = query(tree, GI.extent(geom))

"""recursively query the nodes until a leaf node is reached"""
function query!(query_result::Vector{Int}, node::STRNode, extent::Extent)
    if Extents.intersects(node.extent, extent)
        for child in node.children
            query!(query_result, child, extent)
        end
    end
    return query_result
end

"""when leaf node is reached, push indices of geometries to query result"""
function query!(query_result::Vector{Int}, node::STRLeafNode, extent::Extent)
    for i in eachindex(node.extents)
        if Extents.intersects(node.extents[i], extent)
            push!(query_result, node.indices[i])
        end
    end
end



include("abstracttrees.jl")

export STRtree, query

end
