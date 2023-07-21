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
export isbasicauthrequest, isbearerauthrequest, current_user, current_user_id

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
    authenticated(params::Params) :: Bool

Returns `true` if a user id is stored on the session.
"""
function authenticated(params::Params) :: Bool
  isbearerauthrequest(params) && params[:authuser] !== nothing && return true
  GenieSession.isset(params[:session], USER_ID_KEY)
end
const is_authenticated = authenticated
const isauthenticated = authenticated


function authenticated!(params::Params; exception = Genie.Exceptions.ExceptionalResponse(Genie.Renderer.redirect(:show_login)))
  authenticated(params) || throw(exception)
end


"""
    get_authentication(params::Params) :: Union{Nothing,Any}

Returns the user id stored on the session, if available.
"""
function get_authentication(params::Params) :: Union{Nothing,Any}
  haskey(params, :session) ? GenieSession.get(params, USER_ID_KEY) : nothing
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


function basicauthparams(req, res, params::Params)
  headers = Dict(req.headers)
  if haskey(headers, "Authorization")
    auth = headers["Authorization"]
    if startswith(auth, "Basic ")
      try
        auth = String(base64decode(auth[7:end]))
        auth = split(auth, ":")
        params.collection = ImmutableDict(
          params.collection,
          :username => auth[1],
          :password => auth[2]
        )
      catch
      end
    end
  end

  req, res, params
end


function isbasicauthrequest(params::Params) :: Bool
  haskey(params, :username) && haskey(params, :password)
end


function bearerauthparams(req, res, params::Params)
  headers = Dict(req.headers)
  if haskey(headers, "Authorization")
    auth = headers["Authorization"]
    if startswith(auth, "Bearer ")
      try
        token = auth[8:end] |> strip
        params.collection = ImmutableDict(
          params.collection,
          :token => token
        )
      catch
      end
    end
  end

  req, res, params
end



function isbearerauthrequest(params::Params) :: Bool
  haskey(params, :token)
end


current_user(params::Params) = params[:authuser]
current_user_id(params::Params) = current_user(params) === nothing ? nothing : current_user(params).id


function __init__() :: Nothing
  GenieAuthentication.basicauthparams in Genie.Router.pre_match_hooks || pushfirst!(Genie.Router.pre_match_hooks, GenieAuthentication.basicauthparams)
  GenieAuthentication.bearerauthparams in Genie.Router.pre_match_hooks || pushfirst!(Genie.Router.pre_match_hooks, GenieAuthentication.bearerauthparams)

  nothing
end

end