using Documenter
using CorrelationFunctions

makedocs(sitename = "CorrelationFunctions.jl documentation",
         format   = Documenter.HTML(prettyurls = false,
                                    assets     = [
                                        "assets/code.css"
                                    ]))

deploydocs(repo = "github.com/shamazmazum/CorrelationFunctions.jl.git")
