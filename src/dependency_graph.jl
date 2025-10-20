struct DependencyGraph
    constructors::Vector{Any}
    caches::Vector{Union{Nothing,NTuple{2,String}}}
    dependencies::Vector{Vector{UInt64}}
end

function DependencyGraph(x)
    elements = IdDict{Any,UInt64}()
    deps = Vector{UInt64}[]
    constructors = []
    caches = Union{Nothing,NTuple{2,String}}[]

    graph = DependencyGraph(constructors, caches, deps)

    make_dependency_graph!(graph, elements, x)
    return graph
end

function make_dependency_graph!(graph::DependencyGraph, elements, x)
    if haskey(elements, x)
        return elements[x]
    end

    childdeps, constructor = dependencies(x)
    push!(
        graph.dependencies,
        [make_dependency_graph!(graph, elements, childdep) for childdep in childdeps],
    )

    newidx = length(elements) + 1
    elements[x] = newidx
    push!(graph.constructors, constructor)
    push!(graph.caches, get_cache(x))

    return newidx
end

function construct_outgoing(incoming)
    outgoing = [Int[] for _ in incoming]
    for (i, v) in enumerate(incoming)
        for dep in v
            push!(outgoing[dep], i)
        end
    end
    return outgoing
end

function topological_sort(
    incoming::AbstractVector{<:AbstractVector},
    outgoing::AbstractVector{<:AbstractVector},
)
    ordering = zeros(Int, length(incoming))

    active = BinaryMaxHeap{Tuple{Vector{Int},Int}}()
    for (i, deps) in enumerate(outgoing)
        if isempty(deps)
            push!(active, ([], i))
            ordering[i] = -1
        end
    end

    idx = 0
    while !isempty(active)
        _, vnext = pop!(active)

        ordering[vnext] = idx += 1

        for v in incoming[vnext]
            if all(ordering[dep] > 0 for dep in outgoing[v]) && ordering[v] == 0
                push!(active, (sort!(ordering[outgoing[v]]), v))
                ordering[v] = -1 # prevent readding to heap
            end
        end
    end
    if idx != length(ordering)
        throw(DomainError(outgoing, "attempted topological sort on a cyclic graph."))
    end
    return ordering
end


# Coffman-Graham algorithm
function schedule_stages(
    incoming::AbstractVector{<:AbstractVector},
    maxwidth::Integer = length(incoming),
)
    outgoing = construct_outgoing(incoming)
    ordering = topological_sort(incoming, outgoing)

    levels = zero(ordering)
    stages = Vector{UInt64}[]
    for v in sortperm(ordering, rev = true)
        minlevel = maximum(view(levels, incoming[v]), init = 0) + 1
        stageidx = findfirst(
            stage -> length(stage) < maxwidth,
            view(stages, minlevel:length(stages)),
        )
        if isnothing(stageidx)
            push!(stages, UInt64[v])
            levels[v] = length(stages)
        else
            stageidx += minlevel - 1
            push!(stages[stageidx], v)
            levels[v] = stageidx
        end
    end

    return stages
end

function use_cache_loads(graph::DependencyGraph)
    cache_validity = validate_caches(graph.caches)

    newgraph = deepcopy(graph)
    for (i, (cache, cache_valid)) in enumerate(zip(graph.caches, cache_validity))
        if cache_valid
            load_cache(xs) = load(cache[1], cache[2])
            newgraph.dependencies[i] = UInt64[]
            newgraph.caches[i] = nothing
            newgraph.constructors[i] = load_cache
        end
    end

    return newgraph
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
