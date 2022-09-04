using Documenter

push!(LOAD_PATH,  "../../src")

using GenieAuthentication

makedocs(
    sitename = "GenieAuthentication - Authentication plugin for Genie",
    format = Documenter.HTML(prettyurls = false),
    pages = [
        "Home" => "index.md",
        "GenieAuthentication API" => [
          "GenieAuthentication" => "api/genieauthentication.md",
        ]
    ],
)

deploydocs(
  repo = "github.com/GenieFramework/GenieAuthentication.jl.git",
)
