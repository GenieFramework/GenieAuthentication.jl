"""
Functionality for authenticating Genie users.
"""
module GenieAuthentication

import Genie, SearchLight
import GenieSession, GenieSessionCookieSession
import GeniePlugins
import SHA

using Genie.Context

using Base64

export authenticate, deauthenticate, is_authenticated, isauthenticated, get_authentication, authenticated
export login, logout, with_authentication, without_authentication, @authenticated!, @with_authentication!, authenticated!

const USER_ID_KEY = :__auth_user_id

"""
Stores the user id on the session.
"""
function authenticate(params::Params, user_id::Union{Int,SearchLight.DbId})
  isa(user_id, SearchLight.DbId) && (user_id = user_id.value)
  GenieSession.set!(params, USER_ID_KEY, user_id)
end


"""
    deauthenticate(params::Params)

Removes the user id from the session.
"""
function deauthenticate(params::Params)
  params = GenieSession.unset!(params, USER_ID_KEY)
end


"""
    is_authenticated(params::Params) :: Bool

Returns `true` if a user id is stored on the session.
"""
function is_authenticated(params::Params) :: Bool
  GenieSession.isset(params[:session], USER_ID_KEY)
end

const authenticated = is_authenticated
const isauthenticated = is_authenticated


function authenticated!(params; exception = Genie.Exceptions.ExceptionalResponse(Genie.Renderer.redirect(:show_login)))
  authenticated(params) || throw(exception)
end


"""
    get_authentication(params::Params) :: Union{Nothing,Any}

Returns the user id stored on the session, if available.
"""
function get_authentication(params::Params) :: Union{Nothing,Any}
  haskey(params.collection, :session) ? GenieSession.get(params, USER_ID_KEY) : nothing
end

const authentication = get_authentication


"""
    login(user, params::Params)

Persists on session the id of the user object and returns the session.
"""
function login(params::Params, user::M)::Union{Nothing,GenieSession.Session} where {M<:SearchLight.AbstractModel}
  authenticate(params, getfield(user, Symbol(pk(user))))
end


"""
    logout(params::Params) :: Sessions.Session

Deletes the id of the user object from the session, effectively logging the user off.
"""
function logout(params::Params) :: GenieSession.Session
  deauthenticate(params[:params])
end


"""
    with_authentication(f::Function, fallback::Function, session)
    with_authentication(f::Function, fallback::Function, params::Params)

Invokes `f` only if a user is currently authenticated on the session, `fallback` is invoked otherwise.
"""
function with_authentication(f::Function, fallback::Function, params)
  if ! is_authenticated(params)
    fallback(params)
  else
    f(params)
  end
end


"""
    without_authentication(f::Function, params::Params)

Invokes `f` if there is no user authenticated on the current session.
"""
function without_authentication(f::Function, params::Params)
  ! is_authenticated(params) && f(params)
end


"""
    install(dest::String; force = false, debug = false) :: Nothing

Copies the plugin's files into the host Genie application.
"""
function install(dest::String; force = false, debug = false) :: Nothing
  src = abspath(normpath(joinpath(pathof(@__MODULE__) |> dirname, "..", GeniePlugins.FILES_FOLDER)))

  debug && @info "Preparing to install from $src into $dest"
  debug && @info "Found these to install $(readdir(src))"

  for f in readdir(src)
    debug && @info "Processing $(joinpath(src, f))"
    debug && @info "$(isdir(joinpath(src, f)))"

    isdir(joinpath(src, f)) || continue

    debug && "Installing from $(joinpath(src, f))"

    GeniePlugins.install(joinpath(src, f), dest, force = force)
  end

  nothing
end


function basicauthparams(req, res, params)
  headers = Dict(req.headers)
  if haskey(headers, "Authorization")
    auth = headers["Authorization"]
    if startswith(auth, "Basic ")
      try
        auth = String(base64decode(auth[7:end]))
        auth = split(auth, ":")
        params[:username] = auth[1]
        params[:password] = auth[2]
      catch _
      end
    end
  end

  req, res, params
end


function isbasicauthrequest(params::Params) :: Bool
  haskey(params, :username) && haskey(params, :password)
end


function __init__() :: Nothing
  GenieAuthentication.basicauthparams in Genie.Router.pre_match_hooks || pushfirst!(Genie.Router.pre_match_hooks, GenieAuthentication.basicauthparams)

  nothing
end

end