module STRTreeRecipesBaseExt

import Extents
import RecipesBase
import SortTileRecursiveTree

function _push_plotdata_to_xy!(extent::Extents.Extent, depth::Int64, x::Vector{Vector{Float64}}, y::Vector{Vector{Float64}})
    # Allocate space in the x & y vectors, if necessary.
    if (length(x) < depth)
        push!(x, Float64[])
        push!(y, Float64[])
    end

    dx, dy = values(extent)

    # Convert dx & dy into the x- and y-coordinates for plotting, followed by
    # NaN; see https://docs.juliaplots.org/v1.39/gallery/gr/generated/gr-ref039/
    push!(x[depth], dx[[1,2,2,1,1]]..., NaN)
    push!(y[depth], dy[[1,1,2,2,1]]..., NaN)

    nothing
end

_push_plotdata_to_xy!(node::SortTileRecursiveTree.STRNode, depth::Int64, x::Vector{Vector{Float64}}, y::Vector{Vector{Float64}}) = begin
    # Add this node's Extent to the plotting data.
    _push_plotdata_to_xy!(node.extent, depth, x, y)

    # Continue in a depth-first manner.
    for child in node.children
        _push_plotdata_to_xy!(child, depth + 1, x, y)
    end

    nothing
end

_push_plotdata_to_xy!(node::SortTileRecursiveTree.STRLeafNode, depth::Int64, x::Vector{Vector{Float64}}, y::Vector{Vector{Float64}}) = begin
    # Union over all of the Extents stored in this leaf node
    extent = reduce(Extents.union, node.extents)

    # Add this Extent to the plotting data.
    _push_plotdata_to_xy!(extent, depth, x, y)

    nothing
end

"""
Plot recipe for SortTileRecursiveTree.jl. Plotting is done in a breadth-first
manner, meaning that the root extent is plotted, then all extents at depth 1,
then all extents at depth 2, and so on.

Since this is a plot recipe for Plots.jl, various plot attributes work straightaway:

    plot!(tree)                                      # Add to an existing plot
    plot(tree, aspect_ratio = :equal)                # Set aspect ratio
    plot(tree, seriestype = :shape, fillalpha = 0.1) # Plot shaded, transparent rectangles
    plot(tree, color = :black)                       # Set color to black

among others. There are also two custom plot attributes implemented specifically
for SortTileRecursiveTrees, namely "label_template" and "tree_color_cycle".

Remove the legend ("Root", "Depth 1", ..., "Leaf") by plotting as follows:

    plot(tree, label = "")

Alternatively, change the legend text by supplying a list of three strings with
the custom "label_template" attribute:

    plot(tree, label_template = ["A", "B", "C"])

In this example, if the tree has depth 4, the legend will state:

    "A", "B2", "B3", and "C"

for the root extent, the extents at depth 2 and 3, and the leaves, respectively.
The "tree_color_cycle" attribute can be used as follows:

    plot(tree, tree_color_cycle = [:black, :red, :blue])           # Use custom color cycle
    using ColorSchemes
    plot(tree, tree_color_cycle = ColorSchemes.seaborn_colorblind) # Use cycle from ColorSchemes

Note that the built-in "color" and "label" attributes of Plots.jl completely
override the custom "label_template" and "tree_color_cycle" attributes:

    plot(tree, label = "", label_template = ["A", "B", "C"])     # No label is printed
    plot(tree, color = :blue, tree_color_cycle = [:black, :red]) # Every extent is drawn in blue
"""
RecipesBase.@recipe function f(tree::SortTileRecursiveTree.STRtree; label_template = ["Root", "Depth #", "Leaf"], tree_color_cycle = nothing)
    Lx = Vector{Float64}[]
    Ly = Vector{Float64}[]
    _push_plotdata_to_xy!(tree.rootnode, 1, Lx, Ly)
    tree_height = length(Lx)

    # Plot the extents at each depth using the same color & label.
    for depth ∈ eachindex(Lx)
        # Color
        c = :auto
        if (!isnothing(tree_color_cycle))
            c = tree_color_cycle[mod(depth - 1, length(tree_color_cycle)) + 1]
        end
        # Label
        lbl = ""
        if (length(label_template) ≥ 3)
            if (depth == 1)
                lbl = label_template[1]
            elseif (depth == tree_height)
                lbl = label_template[3]
            else
                lbl = label_template[2] * string(depth)
            end
        end
        # Numeric plotdata
        x, y = Lx[depth], Ly[depth]
        RecipesBase.@series begin
            color --> c
            label --> lbl
            x, y
        end
    end
end

end