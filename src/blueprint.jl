"""
    Blueprint

A blueprint defined using [`B`](@ref). Its positional and keyword arguments can be retrieved using `getindex`. The function can be accessed through its `func` field.

# Examples
```julia-repl; setup=:(using Blueprints)
julia> blueprint = B(repeat, [1,2]; inner=100);
julia> blueprint.func
repeat
julia> blueprint[1]
[1,2]
julia> blueprint[:inner]
100
```

See also: [`B`](@ref), [`construct`](@ref).
"""
struct Blueprint
    func::Any
    args::Vector
    params::Vector{Pair{Symbol,Any}}
end

Base.hash(bp::Blueprint, h::UInt) = hash(bp.params, hash(bp.args, hash(bp.func, h)))

"""
    Blueprints.default_groupname(x) -> String

The default groupname that is used by [`CachedB`](@ref) if only a filename is given. This will usually be a textual representation of the function call. If the representation is longer than `Blueprints.MAX_CACHE_GROUPNAME_LENGTH`, it is replaced by its hash instead.
"""
default_groupname(x) = repr(x)
default_groupname(bp::Blueprint) = default_groupname(bp.func, bp.args, bp.params)

function default_groupname(func, args, params)
    kwargs =
        isempty(params) ? "" :
        ";" * join(("$k=$(default_groupname(v))" for (k, v) in params), ",")

    groupname = "$(func)($(join(default_groupname.(args), ","))$kwargs)"

    if length(groupname) > MAX_CACHE_GROUPNAME_LENGTH || contains(groupname, '/')
        groupname = string(hash(groupname))
    end
    return groupname
end


"""
    B(func, args...; params...)

Defines a blueprint for the evaluation of `func(args...; params...)`.

!!! note
    It is important that the blueprinted function is pure: The function must not modify its inputs and its result must not depend on side effects. This is because [`construct`](@ref) will automatically apply memoization to avoid building the same blueprint more than once. Here, *same* is defined by `isequal`.
"""
B(func, args...; params...) = Blueprint(func, collect(args), collect(params))

"""
    Blueprints.PhonyBlueprint(constructor, dependencies, blueprint::Blueprint)

Looks and serializes like `blueprint`, but actually executes `constructor(dependencies)`.

This is useful mostly in cases where your calculation serializes in a very inefficient way or contains closures. In those cases, you can (at your own risk) mask the calculation behind a *stand-in* `blueprint` so that the result is still pure in terms of the arguments and parameters of blueprint.
"""
struct PhonyBlueprint
    constructor::Any
    dependencies::Vector
    blueprint::Blueprint
end

Base.hash(bp::PhonyBlueprint, h::UInt) = hash(bp.blueprint, h)
default_groupname(bp::PhonyBlueprint) = default_groupname(bp.blueprint)

"""
    CachedBlueprint

A cached blueprint, defined using [`CachedB`](@ref).

# Fields
- `filename`: the JLD2 file used as cache
- `groupname`: the path of the object within the file.
- `blueprint`: the blueprint that is to be cached
"""
struct CachedBlueprint
    filename::String
    groupname::String
    blueprint::Union{Blueprint,PhonyBlueprint}
end

Base.hash(bp::CachedBlueprint, h::UInt) =
    hash(bp.blueprint, hash(bp.groupname, hash(bp.filename, h)))
default_groupname(bp::CachedBlueprint) = default_groupname(bp.blueprint)

"""
    CachedB(filename, func, args...; params...)
    CachedB((filename, groupname), func, args...; params...)

Defines a cached blueprint for the evaluation of `func(args...; params...)`.

On [`construct`](@ref), the result is written to the JLD2 file called `filename` under the groupname `groupname`. If the cache already exists, it is loaded instead.

If `groupname` is omitted, a default group name is chosen using [`default_groupname`](@ref).

!!! note
    Using the default group name only works if all constituents of the blueprint have a `repr` that remains stable between Julia sessions. This is not true for closures.
"""
CachedB((filename, groupname)::NTuple{2,AbstractString}, func, args...; params...) =
    CachedBlueprint(filename, groupname, Blueprint(func, collect(args), collect(params)))
CachedB(filename::AbstractString, func, args...; params...) = CachedBlueprint(
    filename,
    default_groupname(func, args, params),
    Blueprint(func, collect(args), collect(params)),
)

"""
    CachedB(filename, blueprint)
    CachedB((filename, groupname), blueprint)

Promotes a regular `blueprint` into a cached blueprint.
"""
CachedB((filename, groupname)::NTuple{2,AbstractString}, bp::Blueprint) =
    CachedBlueprint(filename, groupname, Blueprint(bp.func, bp.args, bp.params))
CachedB(filename::AbstractString, bp::Union{Blueprint,PhonyBlueprint}) =
    CachedBlueprint(filename, default_groupname(bp), bp)


Base.getindex(bp::Blueprint, idx::Integer) = bp.args[idx]
function Base.getindex(bp::Blueprint, name::Symbol)
    # should we use a dict instead of vector of pairs?
    idx = findfirst(x -> first(x) == name, bp.params)
    if isnothing(idx)
        throw(KeyError("no parameter named $name"))
    end

    return bp.params[idx][2]
end

get_cache(x) = nothing
get_cache(bp::CachedBlueprint) = (bp.filename, bp.groupname)

function open_cachefiles(func, caches, mode; kwargs...)
    cachefiles = [cache[1] for cache in caches if !isnothing(cache)]
    files = Dict(
        filename => jldopen(filename, mode, compress = Bzip2Compressor(); kwargs...) for
        filename in unique(cachefiles)
    )

    try
        func(files)
    finally
        for (_, f) in files
            close(f)
        end
    end
end

function validate_caches(caches::AbstractVector)
    valid = falses(length(caches))

    existing_files = findall(cache -> !isnothing(cache) && isfile(cache[1]), caches)

    open_cachefiles(caches[existing_files], "r"; parallel_read = true) do files
        for i in existing_files
            filename, groupname = caches[i]
            valid[i] = haskey(files, filename) && haskey(files[filename], groupname)
        end
    end
    return valid
end
