using Documenter
using Blueprints

makedocs(
    sitename = "Blueprints.jl",
    format = Documenter.HTML(prettyurls = false),
    modules = [Blueprints],
    warnonly = true,
)

deploydocs(repo = "github.com/lukas-weber/Blueprints.jl.git")
