abstract type AbstractExecutionPolicy end

"""
    MapPolicy(map_func [; maxconcurrency=nothing])

Simple parallel execution policy that allows specifying an implementation of parallel map. In this way, it is possible to construct blueprints either using threads or distributed workflows.

`maxconcurrency` allows setting a maximum number items that `map_func` is called on at once. Use this to limit memory consumption or encourage early caching. By default, there is no limit.
"""
struct MapPolicy <: AbstractExecutionPolicy
    map::Any
    maxconcurrency::Union{Int,Nothing}
end
MapPolicy(map_func; maxconcurrency = nothing) = MapPolicy(map_func, maxconcurrency)

function construct_with_policy(policy::MapPolicy, graph::DependencyGraph; copy = true)
    stages = schedule_stages(
        graph.dependencies,
        something(policy.maxconcurrency, length(graph.dependencies)),
    )
    results = Vector{Any}(undef, length(graph.constructors))
    lifetimes = [
        findlast(stage->any(deps->i in deps, graph.dependencies[stage]), stages) for
        i in eachindex(results)
    ]

    for (t, stage) in enumerate(stages)
        constructors = graph.constructors[stage]
        args = [results[graph.dependencies[i]] for i in stage]

        if copy
            args = deepcopy(args)
        end

        view(results, stage) .= policy.map(fas -> fas[1](fas[2]), zip(constructors, args))

        write_caches(graph.caches[stage], results[stage])

        # unreference unneeded results
        for i in eachindex(results)
            if !isnothing(lifetimes[i]) && t >= lifetimes[i]
                results[i] = nothing
            end
        end
    end

    return results[stages[end][end]]
end

function write_caches(caches, results)
    open_cachefiles(caches, "a+") do files
        for (cache, result) in zip(caches, results)
            if !isnothing(cache)
                filename, groupname = cache
                files[filename][groupname] = result
            end
        end
    end
    return nothing
end

function construct(
    graph::DependencyGraph;
    policy = MapPolicy(map),
    copy = true,
    readonly = false,
)
    graph = use_cache_loads(graph)
    graph = trim_unused(graph, length(graph.dependencies))

    if readonly && any(!isnothing, graph.caches)
        error(
            "Attempted construct with readonly=true, but not all caches are built:\n$(join(filter(!isnothing, graph.caches),'\n'))",
        )
    end

    return construct_with_policy(policy, graph; copy)
end

"""
    construct(x; policy=MapPolicy(map), copy=true, readonly=false)

- If `x` is a blueprint, constructs it.
- If `x` is a cached blueprint, first tries to load from cache, otherwise writes the cache after construction.
- If `x` implements [`Blueprints.dependencies`](@ref), constructs its dependencies recursively and then `x`.
- Else, returns `x`.

Each blueprint will only be constructed once. If another one which is identical (`===`) to it appears, the result is memoized.

`policy` can be used to set an execution policy for parallelization of independent calculations. At the moment, only [`MapPolicy`](@ref) is supported, which allows you to specify a parallel map implementation. In the future, additional policies may be implemented.

If `copy` is enabled, intermediate results will always be deepcopied before they are passed to constructors. This avoids unexpected data dependencies due to memoization, in cases like

```jldoctest construct; setup=:(using Blueprints)
a = B(zeros,4)
result = construct([a,a]; copy=false) # danger!
result[1][1] = 1
result

# output
2-element Vector{Any}:
 [1.0, 0.0, 0.0, 0.0]
 [1.0, 0.0, 0.0, 0.0]
```

If `readonly` is set, construction of cached blueprints will fail if their caches do not yet exist. In this mode, `construct` can be called from multiple processes without coordination on cached blueprints.
```
"""
function construct(x; kwargs...)
    graph = DependencyGraph(x)
    return construct(graph; kwargs...)
end
