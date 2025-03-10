module Blueprints

export B, CachedB, construct, MapPolicy
export Blueprint, CachedBlueprint, PhonyBlueprint

using JLD2
using CodecBzip2

const MAX_CACHE_GROUPNAME_LENGTH = 256

include("blueprint.jl")
include("dependency_graph.jl")
include("dependencies.jl")
include("construct.jl")
include("print.jl")
include("precompile.jl")

end # module Blueprints
