using Documenter, Luxor
using DocumenterTools: Themes
using DocumenterLandingPage
using DocumenterCodeBlocks
using PoincareDisk

# Setup for doctests in docstrings
DocMeta.setdocmeta!(PoincareDisk, :DocTestSetup, :(using PoincareDisk))

println("Starting makedocs")

makedocs(
    modules = [PoincareDisk],
    sitename = "PoincareDisk",
    remotes = nothing,
    warnonly = true,
    plugins = [CodeBlocks()],
    format = Documenter.HTML(
        inventory_version = pkgversion(PoincareDisk),
        size_threshold = nothing,
        prettyurls = get(ENV, "CI", nothing) == "true",
        assets = ["assets/poincaredisk-docs.css"]),
    pages = Any[
        "Introduction"      => "index.md",
        "Basic usage"       => "basics.md",
        "Tiling"            => "tiling.md",
        "Functions"         => "functionindex.md"
    ]
)

println("Finished makedocs")

# deploydocs(
#     push_preview = true,
#     #remotes = nothing,
#     #repo = "github.com/cormullion/PoincareDisk.jl.git",
#     target = "build"
# )