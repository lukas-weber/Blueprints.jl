module Blueprints

export B, CachedB, Blueprint, construct

using JLD2

struct Blueprint
    func::Any
    args::Vector
    params::Vector{Pair{Symbol,Any}}
end

B(func, args...; params...) = Blueprint(func, collect(args), collect(params))

struct CachedBlueprint
    filename::String
    groupname::String
    func::Any
    args::Vector{Any}
    params::Vector{Pair{Symbol,Any}}
end
CachedB((filename, groupname)::NTuple{2,AbstractString}, func, args...; params...) =
    CachedBlueprint(filename, groupname, func, collect(args), collect(params))
CachedB(filename::AbstractString, func, args...; params...) = CachedBlueprint(
    filename,
    default_groupname(func, args, params),
    func,
    collect(args),
    collect(params),
)

Base.getindex(bp::Blueprint, idx::Integer) = bp.args[idx]
function Base.getindex(bp::Blueprint, name::Symbol)
    # should we use a dict instead of vector of pairs?
    idx = findfirst(x -> first(x) == name, bp.params)
    if isnothing(idx)
        throw(KeyError("no parameter named $name"))
    end

    return bp.params[idx][2]
end

function default_groupname(func, args, params)
    kwargs = isempty(params) ? "" : ";" * join(("$k=$v" for (k, v) in params), ",")

    groupname = "$func($(join(string.(args), ","))$kwargs)"

    if length(groupname) > 1000 || contains(groupname, '/')
        groupname = string(hash((func, args, params)))
    end
    return groupname
end


get_cache(x) = nothing
get_cache(bp::CachedBlueprint) = (bp.filename, bp.groupname)

function load_from_cache(bp::CachedBlueprint)
    return load(bp.filename, bp.groupname)
end


struct DependencyGraph
    constructors::Vector{Any}
    caches::Vector{Union{Nothing,NTuple{2,String}}}
    dependencies::Vector{Vector{UInt64}}
end

function DependencyGraph(bp::Union{Blueprint,CachedBlueprint})
    elements = IdDict{Any,UInt64}()
    deps = Vector{UInt64}[]
    constructors = []
    caches = Union{Nothing,NTuple{2,String}}[]

    graph = DependencyGraph(constructors, caches, deps)

    make_dependency_graph!(graph, elements, bp)
    return graph
end

function make_dependency_graph!(graph::DependencyGraph, elements, bp)
    if haskey(elements, bp)
        return elements[bp]
    end

    childdeps, constructor = dependencies(bp)
    push!(
        graph.dependencies,
        [make_dependency_graph!(graph, elements, childdep) for childdep in childdeps],
    )

    newidx = length(elements) + 1
    elements[bp] = newidx
    push!(graph.constructors, constructor)
    push!(graph.caches, get_cache(bp))

    return newidx
end

function topological_sort(deps::AbstractVector{<:AbstractVector})
    stages = Vector{UInt64}[]

    unassigned_vertices = Set(1:length(deps))
    while length(unassigned_vertices) > 0
        push!(
            stages,
            [
                result for
                result in unassigned_vertices if !any(in(unassigned_vertices), deps[result])
            ],
        )

        if isempty(stages[end])
            throw(DomainError(deps, "attempted topological sort on a cyclic graph."))
        end

        for result in stages[end]
            delete!(unassigned_vertices, result)
        end
    end
    return stages
end


function construct(
    graph::DependencyGraph,
    until_stage::Integer;
    map_func = map,
    copy = true,
)
    graph = use_cache_loads(graph)
    stages = topological_sort(graph.dependencies)
    graph = trim_unused(graph, stages[min(length(stages), until_stage)])
    stages = topological_sort(graph.dependencies)

    results = Vector{Any}(undef, length(graph.constructors))
    stages = topological_sort(graph.dependencies)

    maybecopy = copy ? deepcopy : identity

    function apply_constructor(i)
        return graph.constructors[i](view(results, graph.dependencies[i]))
    end

    for stage in stages
        view(results, stage) .= map_func(apply_constructor, stage)

        open_cachefiles(view(graph.caches, stage), "a+") do files
            for (cache, result) in zip(view(graph.caches, stage), view(results, stage))
                if !isnothing(cache)
                    filename, groupname = cache
                    files[filename][groupname] = result
                end
            end
        end
    end

    return results[stages[end]]
end

function construct(graph::DependencyGraph; kwargs...)
    return construct(graph, length(graph.dependencies); kwargs...)[end]
end


function construct(bp::Union{Blueprint,CachedBlueprint}, args...; kwargs...)
    graph = DependencyGraph(bp)
    return construct(graph, args...; kwargs...)
end

construct(x) = construct(B(identity, x))


function open_cachefiles(func, caches, mode)
    cachefiles = [cache[1] for cache in caches if !isnothing(cache)]
    files = Dict(
        filename => jldopen(filename, mode, compress = true) for
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

    open_cachefiles(caches[existing_files], "r") do files
        for i in existing_files
            filename, groupname = caches[i]
            valid[i] = haskey(files, filename) && haskey(files[filename], groupname)
        end
    end
    return valid
end

function use_cache_loads(graph::DependencyGraph)
    cache_validity = validate_caches(graph.caches)

    deps = map(
        (cache, cache_valid, childdeps) ->
            isnothing(cache) || !cache_valid ? childdeps : UInt64[],
        graph.caches,
        cache_validity,
        graph.dependencies,
    )
    constructors = map(
        (cache, cache_valid, constructor) ->
            isnothing(cache) || !cache_valid ? constructor : xs -> load(cache[1], cache[2]),
        graph.caches,
        cache_validity,
        graph.constructors,
    )
    caches =
        [valid ? nothing : cache for (valid, cache) in zip(cache_validity, graph.caches)]

    return DependencyGraph(constructors, caches, deps)
end

function trim_unused(deps, finals)
    used_deps = Set{UInt64}()
    function visit!(visited, deps, idx)
        push!(visited, idx)
        for child in deps[idx]
            if !(child in visited)
                visit!(visited, deps, child)
            end
        end
    end

    for final in finals
        visit!(used_deps, deps, final)
    end

    index_map = collect(used_deps)
    inv_index_map = zeros(UInt64, length(deps))
    for (new, old) in enumerate(index_map)
        inv_index_map[old] = new
    end

    new_deps = [getindex.(Ref(inv_index_map), deps[idx]) for idx in index_map]

    return new_deps, index_map
end

function trim_unused(graph::DependencyGraph, finals)
    new_deps, index_map = trim_unused(graph.dependencies, finals)

    return DependencyGraph(graph.constructors[index_map], graph.caches[index_map], new_deps)
end

dependencies(x) = [], Returns(x)
function dependencies(x::AbstractArray)
    depsconstructors = dependencies.(x)

    deps = map(first, depsconstructors)
    constructors = map(last, depsconstructors)

    dep_lengths = length.(deps)

    function constructor(xs)
        idx = 0
        args = map(len -> view(xs, idx+1:(idx+=len)), dep_lengths)

        return [c(arg) for (c, arg) in zip(constructors, args)]
    end

    return reduce(vcat, deps), constructor
end

function dependencies(x::AbstractDict)
    keydeps, keyconstructor = dependencies(collect(keys(x)))
    valuedeps, valueconstructor = dependencies(collect(values(x)))

    function constructor(xs)
        keyxs = keyconstructor(view(xs, 1:length(keydeps)))
        valuexs = valueconstructor(view(xs, length(keydeps)+1:length(xs)))

        return Dict((k => v for (k, v) in zip(keyxs, valuexs)))
    end

    return vcat(keydeps, valuedeps), constructor
end

function dependencies(bp::Union{CachedBlueprint,Blueprint})
    deps = vcat(collect(bp.args), collect(last.(bp.params)))

    param_keys = first.(bp.params)
    nargs = length(bp.args)
    f = bp.func
    function constructor(xs)
        args = view(xs, 1:nargs)
        params = view(xs, nargs+1:length(xs))

        kwargs = Pair{Symbol,Any}[k => v for (k, v) in zip(param_keys, params)]

        return f(args...; kwargs...)
    end
    return deps, constructor
end

function Base.show(io::IO, ::MIME"text/plain", g::DependencyGraph)
    stages = topological_sort(g.dependencies)

    println(io, "DependencyGraph:")
    for (i, stage) in enumerate(stages)
        println(io, "Stage $i:")
        for j in stage
            constructor = g.constructors[j]
            if constructor isa Returns
                name = constructor()
            elseif hasproperty(constructor, :f)
                name = constructor.f
            else
                name = Base.return_types(constructor)[1]
            end


            args = "($(join(g.dependencies[j], ",")))"
            if args == "()"
                args = ""
            end
            println(io, " $j. $name$args")
        end
    end
end

include("precompile.jl")

end # module Blueprints
