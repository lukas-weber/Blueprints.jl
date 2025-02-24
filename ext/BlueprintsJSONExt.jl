module BlueprintsJSONExt

using Blueprints
using JSON

JSON.lower(bp::Blueprint) = merge(
    Dict("func" => string(bp.func)),
    Dict(i => arg for (i, arg) in enumerate(bp.args)),
    Dict(key => value for (key, value) in bp.params),
)

end
