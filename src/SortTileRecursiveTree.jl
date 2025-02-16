module SortTileRecursiveTree

using Extents
import GeoInterface as GI


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
    ext1 = GI.extent(first(geoms))
    extents_indices = Tuple{typeof(ext1),Int}[(GI.extent(geoms[i]), i) for i in eachindex(geoms)]
    # Use the same scratch space for all sorts
    scratch = similar(extents_indices)
    sort!(extents_indices; by=v -> (v[1][1][1] + v[1][1][2]) / 2, scratch)  # [extent/index][dim][min/max] sort by x
    r = length(extents_indices)
    P = ceil(Int, r / nodecapacity)
    S = ceil(Int, sqrt(P))
    x_splits = Iterators.partition(extents_indices, S * nodecapacity)
    
    nodes = STRLeafNode{Vector{typeof(extents_indices[1][1])}}[]
    for x_split in x_splits
        sort!(x_split; 
            by=v -> (v[1][2][1] + v[1][2][2]) / 2, # [extent/index][dim][min/max] sort by y
            scratch=resize!(scratch, length(x_split)),
        ) 
        y_splits = Iterators.partition(x_split, nodecapacity)
        for y_split in y_splits
            exts = first.(y_split)::Vector{typeof(ext1)}
            inds = last.(y_split)::Vector{Int}
            push!(nodes, STRLeafNode(exts, inds))
        end
    end
    return nodes
end


# a bit of duplication...
function parentnodes(nodes; nodecapacity=10)
    n1 = first(nodes)
    ext1 = GI.extent(n1)
    extents_indices = Tuple{typeof(ext1),typeof(n1)}[(GI.extent(node), node) for node in nodes]
    scratch = similar(extents_indices)
    sort!(extents_indices; by=v -> (v[1][1][1] + v[1][1][2]) / 2, scratch)  # [extent/node][dim][min/max] sort by x
    r = length(extents_indices)
    P = ceil(Int, r / nodecapacity)
    S = ceil(Int, sqrt(P))
    x_splits = Iterators.partition(extents_indices, S * nodecapacity)
    
    T = typeof(extents_indices[1][1])
    N = Vector{typeof(extents_indices[1][2])}
    outnodes = STRNode{T, N}[]
    for x_split in x_splits
        sort!(x_split; 
            by=v -> (v[1][2][1] + v[1][2][2]) / 2, # [extent/index][dim][min/max] sort by y
            scratch=resize!(scratch, length(x_split)),
        ) 
        y_splits = Iterators.partition(x_split, nodecapacity)
        for y_split in y_splits
            # Alloc free union over the extents
            ext = foldl(y_split; init=y_split[1][1]) do u, (ext, _)
                Extents.union(u, ext)
            end
            y_splitnodes = last.(y_split)::Vector{eltype(nodes)}
            push!(outnodes, STRNode(ext, y_splitnodes))
        end
    end
    return outnodes
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


export STRtree, query

end
