# Blueprints.jl
[![](https://img.shields.io/badge/docs-stable-blue.svg)](https://lukas-weber.github.io/Blueprints.jl/stable)
[![](https://img.shields.io/badge/docs-dev-blue.svg)](https://lukas-weber.github.io/Blueprints.jl/dev)
[![CI](https://github.com/lukas-weber/Blueprints.jl/actions/workflows/main.yml/badge.svg)](https://github.com/lukas-weber/Blueprints.jl/actions/workflows/main.yml)

Blueprints.jl implements serializable thunks that can be constructed in parallel using memoization and cached automatically.

## Example
For an example when this is useful, imagine the following situation: You are running a simulation code that takes a dictionary of parameters.

```julia
parameters = Dict(
    :temperature => 0.1,
    :coupling => 2.0,
    :grid => square_grid(100, 100; dx = 0.1)
)

function (@main)(args)
    run_code("data/mycalculation", parameters)
end
```

It would be nice for the code to save its parameters along with the results. For temperature and coupling this works well, but saving the grid seems like a huge waste of space. What we really want to save is the information about what *kind* of grid we used.

Enter Blueprints.jl:
```julia
using Blueprints

parameters = Dict(
    :temperature => 0.1,
    :coupling => 2.0,
    :grid => B(square_grid, 100, 100; dx = 0.1)
)

function (@main)(args)
    run_code("data/mycalculation", parameters)
end
```

This defers the construction of the grid to later. Inside of `run_code` we have to replace `grid = parameters[:grid]` by `grid = construct(parameters[:grid])` to construct the blueprint. If the argument of `construct` does not contain any blueprints, it is a no-op.

Serializing the blueprint with JSON.jl will yield

```json
  {"func": "square_grid", "1": 100, "2": 100, "dx": 0.1}
```

If `square_grid` is an expensive function, we can also cache it to JLD2 by writing

```julia
    :grid => CachedB("cache_file.jld2", square_grid, 100, 100; dx = 0.1)
```

Blueprints can be nested and nested blueprints can be constructed in parallel. For more information, see the documentation.

## Overlap with other packages

The thing Blueprints tries to do lies somewhere inbetween two other great packages, [DrWatson.jl](https://github.com/JuliaDynamics/DrWatson.jl) and [Dagger.jl](https://github.com/JuliaParallel/Dagger.jl), which may either be more appropriate for your specialized use case or be used together with Blueprints.jl.

- **DrWatson.jl**: Is a collection of tools for scientific project management. Among many other things, it allows building parameterized and cached data processing workflows. Encoding the dependencies of workflows and their execution order requires some manual effort, however. Due to the very modular nature of DrWatson.jl, it can be used together with Blueprints.jl for that purpose.

- **Dagger.jl**: Is a parallel computing framework. Its directional acyclic graph execution model resembles the one of Blueprints.jl very much but does not place a focus on serializability. Blueprints.jl, on the other hand, is much less ambitious in terms of parallelization. Blueprints.jl does not prescribe a specific parallelization framework and can make use of any parallel map implementation out of the box. In the future, support for more fine-grained parallelization using Dagger.jl may be implemented.
