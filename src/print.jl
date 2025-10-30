function Base.show(io::IO, ::MIME"text/plain", bp::Blueprint)
    graph = DependencyGraph(bp)
    print(io, "Blueprint with ")
    show(io, MIME"text/plain"(), graph)
end

function Base.show(io::IO, ::MIME"text/plain", bp::PhonyBlueprint)
    graph = DependencyGraph(bp.blueprint)
    print(io, "(Phony) Blueprint with ")
    show(io, MIME"text/plain"(), graph)
end

function Base.show(io::IO, ::MIME"text/plain", bp::CachedBlueprint)
    graph = DependencyGraph(bp)
    print(io, "CachedBlueprint saving to\n$(bp.filename):/$(bp.groupname)\nwith ")
    show(io, MIME"text/plain"(), graph)
end

function Base.show(io::IO, ::MIME"text/plain", g::DependencyGraph)
    stages = schedule_stages(g.dependencies)

    println(io, "DependencyGraph:")
    for (i, stage) in enumerate(stages)
        println(io, "Stage $i:")
        for j in sort(stage)
            constructor = g.constructors[j]
            if constructor isa Returns
                name = repr(constructor())
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
