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


function topological_sort(incoming::AbstractVector{<:AbstractVector})
    ordering = zeros(Int, length(incoming))

    unassigned_vertices = Set(1:length(incoming))
    idx = 0
    while length(unassigned_vertices) > 0
        vnext = nothing
        maxscore = nothing
        for v in unassigned_vertices
            if !any(in(unassigned_vertices), incoming[v])
                score = sort!(ordering[incoming[v]], rev = true)
                if isnothing(maxscore) || score > maxscore
                    vnext = v
                    maxscore = score
                end
            end
        end

        if isnothing(vnext)
            throw(DomainError(incoming, "attempted topological sort on a cyclic graph."))
        end


        ordering[vnext] = idx += 1
        delete!(unassigned_vertices, vnext)
    end
    return ordering
end


# Coffman-Graham algorithm
function schedule_stages(
    incoming::AbstractVector{<:AbstractVector},
    maxwidth::Integer = length(incoming),
)
    ordering = topological_sort(incoming)

    outgoing = [findall(d->in(i, d), incoming) for i in eachindex(incoming)]
    levels = zero(ordering)
    stages = Vector{UInt64}[]
    for v in sortperm(ordering, rev = true)
        minlevel = maximum(view(levels, outgoing[v]), init = 0) + 1
        stageidx = findfirst(
            stage->length(stage) < maxwidth,
            view(stages, minlevel:length(stages)),
        )
        if isnothing(stageidx)
            push!(stages, UInt64[v])
            levels[v] = length(stages)
        else
            stageidx += minlevel-1
            push!(stages[stageidx], v)
            levels[v] = stageidx
        end
        @assert !any(in(stages[levels[v]]), incoming[v])
    end

    return reverse(stages)
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
