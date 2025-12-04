module BlueprintsJSONExt

using Blueprints
using JSON

function JSON.lower(bp::Blueprint)
    return merge(
        Dict("func" => string(bp.func)),
        Dict(i => arg for (i, arg) in enumerate(bp.args)),
        Dict(key => value for (key, value) in bp.params),
    )
end

JSON.lower(bp::CachedBlueprint) = merge(
    Dict("filename" => bp.filename, "groupname" => bp.groupname),
    JSON.lower(bp.blueprint),
)

JSON.lower(bp::PhonyBlueprint) = JSON.lower(bp.standin_blueprint)

end
