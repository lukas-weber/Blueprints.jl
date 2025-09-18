using Test
using Random
using Blueprints
using Carlo
using Carlo.JobTools

test_func(args...; kwargs...) = (args, kwargs)
blueprint_test_func(args...; kwargs...) = B(test_func, args...; kwargs...)

function random_directed_acyclic_graph(items, maximum_dependencies)
    ordered = Vector{Int}[
        i == 1 ? Int[] : unique(rand(1:i-1, rand(1:maximum_dependencies))) for i = 1:items
    ]
    p = randperm(items)

    for o in ordered
        for i in eachindex(o)
            o[i] = p[o[i]]
        end
    end

    disordered = similar(ordered)
    disordered[p] .= ordered

    return disordered
end


function topological_sort_naive(incoming)
    ordering = zeros(Int, length(incoming))

    unassigned_vertices = Set(1:length(incoming))
    idx = 0
    while length(unassigned_vertices) > 0
        vnext = nothing
        maxscore = nothing
        for v in unassigned_vertices
            if !any(in(unassigned_vertices), incoming[v])
                score = (sort!(ordering[incoming[v]], rev = true), v)
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

@testset "topological_sort" begin
    deps = [[2, 3, 3, 5], [], [2, 4], [], [2]]

    ordering = Blueprints.topological_sort(deps)
    @test all(all(ordering[i] .> ordering[deps[i]]) for i in eachindex(deps))

    deps = random_directed_acyclic_graph(100, 5)
    @test Blueprints.topological_sort(deps) == topological_sort_naive(deps)

    cyclic_deps = [[2], [1]]
    @test_throws DomainError Blueprints.topological_sort(cyclic_deps)
end

@testset "schedule_stages" begin
    deps = [[2, 3, 3, 5], [], [2, 4], [], [2]]
    stages = [[2, 4], [3, 5], [1]]
    @test sort.(Blueprints.schedule_stages(deps)) == stages
    @test Blueprints.schedule_stages(Vector[]) == []
    @test Blueprints.schedule_stages([[]]) == [[1]]

    deps = vcat(fill(Int[], 40), map(x -> [x], 1:40), [collect(1:80)])
    stages = Blueprints.schedule_stages(deps, 7)
    @test all(length.(stages) .<= 7)

end

function canonicalize_deps(deps)
    order = invperm(sortperm(deps))

    out = deepcopy(deps)
    for (i, o) in enumerate(order)
        out[o] = sort(Int[order[d] for d in deps[i]])
    end
    return out
end

@testset "trim_unused" begin
    deps = [[2, 3, 3, 5], [], [2, 4], [], [2]]

    @test Blueprints.trim_unused(deps, [2]) == ([[]], [2])
    @test canonicalize_deps(Blueprints.trim_unused(deps, [3])[1]) == [[], [], [1, 2]]
end

@testset "dependencies" begin
    objs = [
        1,
        [1, 2, 3],
        Dict("a" => π, π => "b"),
        (1, 2, 3),
        (; a = π, b = exp(1)),
        rand(4, 4),
        [(1, Dict(3 => 4)), Dict([1, 2] => (; a = rand(4, 4)))],
    ]

    for obj in objs
        deps, constructor = Blueprints.dependencies(obj)
        @test obj == constructor(deps)
    end
end

@testset "Blueprint" begin
    @testset for maxconcurrency = 1:5
        @test construct(
            fill(B(identity, 1), 3, 3),
            policy = MapPolicy(map; maxconcurrency),
        ) == ones(3, 3)

        bps = map((test_func, blueprint_test_func)) do f
            bp = f(1, 2, 3; a = 9)
            bp2 = f(bp, [bp, bp, 1], 2)
            bp3 = f(; c = Dict(bp => bp2))
            return f(bp3; c = bp3)
        end

        @test bps[1] == construct(bps[2], policy = MapPolicy(map; maxconcurrency))
    end
end

@testset "CachedBlueprint" begin

    mktempdir() do dir
        file1 = dir * "/test.jld2"
        file2 = dir * "/test2.jld2"

        bp = B(test_func, 1, 2, 3)
        bp2 = CachedB(file1, test_func; a = 3, b = 4, c = 5)
        bp3 = CachedB(file1, test_func; a = bp2)
        bp4 = CachedB((file2, "test"), test_func; a = bp2)
        bp5 = CachedB(file2, test_func, bp, bp2, bp3; c = bp4)
        bp6 = B(test_func, bp5)

        graph = Blueprints.DependencyGraph(bp5)

        @test !any(Blueprints.validate_caches(graph.caches))

        reduced_graph = Blueprints.use_cache_loads(graph)
        @test reduced_graph.caches == graph.caches
        # @test reduced_graph.constructors === graph.constructors
        @test reduced_graph.dependencies == graph.dependencies

        result1 = construct(bp6)
        result1r = construct(bp6)
        @test result1 == result1r

        rm(file1)
        rm(file2)
        result2 = construct(bp6)

        @test result1 == result2
    end
end

@testset "BlueprintsCarloExt" begin
    job = JobInfo(
        "test",
        AbstractMC;
        checkpoint_time = "10:00",
        run_time = "10:00",
        tasks = [
            TaskInfo(
                "test",
                Dict(
                    :sweeps => 1,
                    :thermalization => 2,
                    :binsize => 3,
                    :a => B(identity, 1),
                ),
            ),
        ],
    )

    job2 = construct(job)
    @test job2.tasks[1].params[:a] == 1
end
