
"""
    Blueprints.dependencies(x) -> (AbstractVector, Function)

Returns the dependencies of `x` as a tuple of a vector `deps` and a constructor `f` so that `f(deps) == x`.

Defining this method allows [`construct`](@ref)ing `x` transparently: If any of the dependencies are [`Blueprint`](@ref)s, they will be recursively constructed before the whole type is. For example, constructing an array of blueprints will return an array of constructed blueprints.
"""
function dependencies end

dependencies(x) = [], Returns(x)

function dependencies(x::AbstractArray)
    shape = size(x)
    return vec(x), y -> collect(reshape(y, shape))
end

function dependencies(x::AbstractDict)
    keycount = length(keys(x))

    function constructor(xs)
        keyxs = view(xs, 1:keycount)
        valuexs = view(xs, keycount+1:length(xs))

        return Dict((k => v for (k, v) in zip(keyxs, valuexs)))
    end

    # do not use vcat since it will promote to common type
    return collect(Iterators.flatten((keys(x), values(x)))), constructor
end

function dependencies(x::Tuple)
    return collect(x), y -> tuple(y...)
end

function dependencies(x::NamedTuple)
    ks = keys(x)

    function constructor(xs)
        return (; map(Pair, ks, xs)...)
    end

    return collect(values(x)), constructor
end

dependencies(bp::CachedBlueprint) = dependencies(bp.blueprint)

function dependencies(bp::Blueprint)
    deps = collect(Iterators.flatten((bp.args, last.(bp.params))))

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

dependencies(bp::PhonyBlueprint) = bp.dependencies, bp.constructor
