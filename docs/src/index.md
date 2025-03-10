# Blueprints.jl

Blueprints.jl implements thunks that are **serializable**, constructable in **parallel** using **memoization** and **caching**.


```jldoctest main
using Blueprints

blueprint = B(+, 1, 2)
result = construct(blueprint)

# output
3
```

This makes them a useful building block for reproducible data workflows.

## Nesting

Blueprints can be nested.

```jldoctest main; output = false
initialize_matrix(n,m; factor = 1) = factor * reshape(1:n*m, n, m)

a = B(initialize_matrix, 3, 3)
b = B(initialize_matrix, 3, 1; factor = 1/2)

blueprint = B(*, a, b)
result = construct(blueprint)

# output
3×1 Matrix{Float64}:
 15.0
 18.0
 21.0
```

During construction intermediate results are automatically reused in construction if their blueprints are identical (as defined by `===`).
 
```jldoctest main
function initialize_matrix(n,m; factor = 1)
    println("call $n, $m")
    return factor * reshape(1:n*m, n, m)
end

a = B(initialize_matrix, 3, 3)
println(construct(B(+, a, a)))

# but:
b = B(initialize_matrix, 3, 3)
@show a === b
println(construct(B(+, a, b)))
# output

call 3, 3
[2 8 14; 4 10 16; 6 12 18]
a === b = false
call 3, 3
call 3, 3
[2 8 14; 4 10 16; 6 12 18]
```
Nesting blueprints also works transparently with standard containers.
```jldoctest main
blueprint = B(sum, [a,a,a,b,b,b])
construct(Dict(:a=>a, :r => blueprint))
# output
call 3, 3
call 3, 3
Dict{Symbol, Matrix{Int64}} with 2 entries:
  :a => [1 4 7; 2 5 8; 3 6 9]
  :r => [6 24 42; 12 30 48; 18 36 54]
```

This can be extended to custom types by implementing [`Blueprints.dependencies`](@ref).

## Serialization
Blueprints can be serialized to JSON.

```jldoctest
using Blueprints
using JSON

blueprint = B(repeat, [1,2]; inner = 100)
JSON.print(blueprint)

# output

{"func":"repeat","1":[1,2],"inner":100}
```
This is much more compact and readable than having the actual 200-element array in JSON.

## Caching

To cache any (intermediate) result, all you have to do is to replace [`B`](@ref) by [`CachedB`](@ref) and specify a save location for a JLD2 cache file.

```jldoctest main; setup=:(cache_dir = mktempdir())
# cache_dir = ...

x = CachedB(cache_dir * "/cache.jld2", initialize_matrix, 3,3)
y = CachedB(cache_dir * "/cache.jld2", initialize_matrix, 3,1)
result = B(sum, B(*,x,y))

println(construct(result))
println(construct(result))
# output
call 3, 3
call 3, 1
108
108
```
By default, results will be saved in the given file under a default group name based on the blueprint arguments (see [`Blueprints.default_groupname`](@ref)). To specify the group name manually, use
```julia
x = CachedB((cache_dir * "/cache.jld2", "my_groupname"), initialize_matrix, 3,3)
construct(x)

using JLD2
y = jldopen(cache_dir * "/cache.jld2", "my_groupname")
x == y

# output
true
```

## Parallel construction

To parallelize the construction of heavy blueprints, you can pass an execution policy. For now, the only supported policy is [`MapPolicy`](@ref), which lets you specify a parallel map implementation of your choice.

```jldoctest main; output = false 
blueprint = B(sum, [a,a,a,b,b,b])
construct(Dict(:a=>a, :r => blueprint); policy=MapPolicy(Threads.map))

# output
call 3, 3
call 3, 3
Dict{Symbol, Matrix{Int64}} with 2 entries:
  :a => [1 4 7; 2 5 8; 3 6 9]
  :r => [6 24 42; 12 30 48; 18 36 54]
```
