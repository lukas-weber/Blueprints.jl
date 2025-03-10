using Documenter
using Blueprints

makedocs(
    sitename = "Blueprints",
    format = Documenter.HTML(prettyurls = false),
    modules = [Blueprints],
    warnonly = true,
)

deploydocs(repo = "github.com/lukas-weber/Blueprints.jl.git")
