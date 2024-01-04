# GISTRtree

[![Build Status](https://github.com/maxfreu/GISTRtree.jl/actions/workflows/CI.yml/badge.svg?branch=main)](https://github.com/maxfreu/GISTRtree.jl/actions/workflows/CI.yml?query=branch%3Amain)

An STR tree implementation for GeoInterface compatible geometries.

Usage:

```julia
using GISTRtree
using Extents

tree = STRtree(geometries)
query_result = query(tree, Extent(X=(0, 100.5), Y=(0, 1.5)))
# or 
query_result = query(tree, query_geometry)
```

Contributions are welcome! :)