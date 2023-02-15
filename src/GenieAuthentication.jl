"""
Functionality for authenticating Genie users.
"""
module GenieAuthentication

import Genie, SearchLight
import GenieSession, GenieSessionFileSession
import GeniePlugins
import SHA

using Base64

export authenticate, deauthenticate, is_authenticated, isauthenticated, get_authentication, authenticated
export login, logout, with_authentication, without_authentication, @authenticated!, @with_authentication!, authenticated!


module Token
  using Genie
  using Genie.Encryption
  using Genie.Requests
  using Genie.Responses
  # using JSONWebTokens
  using Random

  export generate_token

  # const jwt_secret_key = ENV["JWT_SECRET_KEY"]
  # const encoding = JSONWebTokens.HS256(jwt_secret_key)

  function generate_token(user)
    # jwt_token = JSONWebTokens.encode(encoding, user)
    # return jwt_token

    Random.seed!( rand(1:100000) )
    token = randstring(12)

    return token
  end

  # JWT_SECRET_KEY ENV["JWT_SECRET_KEY"]

  function __init__()
    # generate .env file for jwt
    # isfile(".env") && touch(".env")

    # try
    #   open(".env", "a") do iostream
    #     write(iostream, "JWT_SECRET_KEY=genieusr")
    #   end
    # catch e
    #   @error e
    # end

    # if ENV["auth"] == "yes"
      # create migration to add access token in db
    # end
    # @info "!! If using token based authentication modify secret key in .env file !!"
  end
end

const USER_ID_KEY = :__auth_user_id
const PARAMS_USERNAME_KEY = :username
const PARAMS_PASSWORD_KEY = :password

"""
Stores the user id on the session.
"""
function authenticate(user_id::Any, session::GenieSession.Session) :: GenieSession.Session
  GenieSession.set!(session, USER_ID_KEY, user_id)
end
function authenticate(user_id::SearchLight.DbId, session::GenieSession.Session)
  authenticate(Int(user_id.value), session)
end
function authenticate(user_id::Union{String,Symbol,Int,SearchLight.DbId}, params::Dict{Symbol,Any} = Genie.Requests.payload()) :: GenieSession.Session
  authenticate(user_id, params[:SESSION])
end

"""
    deauthenticate(session)
    deauthenticate(params::Dict{Symbol,Any})

Removes the user id from the session.
"""
function deauthenticate(session::GenieSession.Session) :: GenieSession.Session
  Genie.Router.params!(:SESSION, GenieSession.unset!(session, USER_ID_KEY))
end
function deauthenticate(params::Dict = Genie.Requests.payload()) :: GenieSession.Session
  deauthenticate(get(params, :SESSION, nothing))
end


"""
    is_authenticated(session) :: Bool
    is_authenticated(params::Dict{Symbol,Any}) :: Bool

Returns `true` if a user id is stored on the session.
"""
function is_authenticated(session::Union{GenieSession.Session,Nothing}) :: Bool
  GenieSession.isset(session, USER_ID_KEY)
end
function is_authenticated(params::Dict = Genie.Requests.payload()) :: Bool
  is_authenticated(get(params, :SESSION, nothing))
end

const authenticated = is_authenticated
const isauthenticated = is_authenticated


"""
    @authenticate!(exception::E = ExceptionalResponse(Genie.Renderer.redirect(:show_login)))

If the current request is not authenticated it throws an ExceptionalResponse exception.
"""
macro authenticated!(exception = Genie.Exceptions.ExceptionalResponse(Genie.Renderer.redirect(:show_login)))
  :(authenticated!($exception))
end

macro with_authentication!(ex, exception = Genie.Exceptions.ExceptionalResponse(Genie.Renderer.redirect(:show_login)))
  quote
    if ! GenieAuthentication.authenticated()
      throw($exception)
    else
      esc(ex)
    end
  end |> esc
end

function authenticated!(exception = Genie.Exceptions.ExceptionalResponse(Genie.Renderer.redirect(:show_login)))
  authenticated() || throw(exception)
end


"""
    get_authentication(session) :: Union{Nothing,Any}
    get_authentication(params::Dict{Symbol,Any}) :: Union{Nothing,Any}

Returns the user id stored on the session, if available.
"""
function get_authentication(session::GenieSession.Session) :: Union{Nothing,Any}
  GenieSession.get(session, USER_ID_KEY)
end
function get_authentication(params::Dict = Genie.Requests.payload()) :: Union{Nothing,Any}
  haskey(params, :SESSION) ? get_authentication(params[:SESSION]) : nothing
end

const authentication = get_authentication


"""
    login(user, session)
    login(user, params::Dict{Symbol,Any})

Persists on session the id of the user object and returns the session.
"""
function login(user::M, session::GenieSession.Session)::Union{Nothing,GenieSession.Session} where {M<:SearchLight.AbstractModel}
  authenticate(getfield(user, Symbol(pk(user))), session)
end
function login(user::M, params::Dict = Genie.Requests.payload())::Union{Nothing,GenieSession.Session} where {M<:SearchLight.AbstractModel}
  login(user, params[:SESSION])
end

"""
    logout(session) :: Sessions.Session
    logout(params::Dict{Symbol,Any}) :: Sessions.Session

Deletes the id of the user object from the session, effectively logging the user off.
"""
function logout(session::GenieSession.Session) :: GenieSession.Session
  deauthenticate(session)
end
function logout(params::Dict = Genie.Requests.payload()) :: GenieSession.Session
  logout(params[:SESSION])
end


"""
    with_authentication(f::Function, fallback::Function, session)
    with_authentication(f::Function, fallback::Function, params::Dict{Symbol,Any})

Invokes `f` only if a user is currently authenticated on the session, `fallback` is invoked otherwise.
"""
function with_authentication(f::Function, fallback::Function, session::Union{GenieSession.Session,Nothing})
  if ! is_authenticated(session)
    fallback()
  else
    f()
  end
end
function with_authentication(f::Function, fallback::Function, params::Dict = Genie.Requests.payload())
  with_authentication(f, fallback, params[:SESSION])
end


"""
    without_authentication(f::Function, session)
    without_authentication(f::Function, params::Dict{Symbol,Any})

Invokes `f` if there is no user authenticated on the current session.
"""
function without_authentication(f::Function, session::GenieSession.Session)
  ! is_authenticated(session) && f()
end
function without_authentication(f::Function, params::Dict = Genie.Requests.payload())
  without_authentication(f, params[:SESSION])
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
        params[PARAMS_USERNAME_KEY] = auth[1]
        params[PARAMS_PASSWORD_KEY] = auth[2]
      catch _
      end
    end
  end

  req, res, params
end


function isbasicauthrequest(params::Dict = Genie.Requests.payload()) :: Bool
  haskey(params, PARAMS_USERNAME_KEY) && haskey(params, PARAMS_PASSWORD_KEY)
end


function __init__() :: Nothing
  GenieAuthentication.basicauthparams in Genie.Router.pre_match_hooks || pushfirst!(Genie.Router.pre_match_hooks, GenieAuthentication.basicauthparams)

  nothing
end

end