"""
Functionality for authenticating Genie users.
"""
module GenieAuthentication

using Genie, Genie.Sessions, Genie.Plugins, Genie.Router, SearchLight, Genie.Requests
using Nullables

export current_user, current_user!!
export authenticate, deauthenticate, is_authenticated, get_authentication, authenticated
export login, logout, with_authentication, without_authentication

const USER_ID_KEY = :__auth_user_id


"""
    authenticate(user_id::Union{String,Symbol,Int}, session) :: Sessions.Session
    authenticate(user_id::Union{String,Symbol,Int}, params::Dict{Symbol,Any}) :: Sessions.Session

Stores the user id on the session.
"""
function authenticate(user_id::Union{String,Symbol,Int,Nullable}, session::Sessions.Session) :: Sessions.Session
  isa(user_id, Nullable) && (user_id = Base.get(user_id))
  Sessions.set!(session, USER_ID_KEY, user_id)
end
function authenticate(user_id::Union{String,Symbol,Int,Nullable}, params::Union{Router.Params,Dict{Symbol,Any}}) :: Sessions.Session
  authenticate(user_id, params[:SESSION])
end
function authenticate(user_id::Union{String,Symbol,Int,Nullable}) :: Sessions.Session
  authenticate(user_id, payload()[:SESSION])
end


"""
    deauthenticate(session) :: Sessions.Session
    deauthenticate(params::Dict{Symbol,Any}) :: Sessions.Session

Removes the user id from the session.
"""
function deauthenticate(session::Sessions.Session) :: Sessions.Session
  Sessions.unset!(session, USER_ID_KEY)
end
function deauthenticate(params::Union{Router.Params,Dict{Symbol,Any}}) :: Sessions.Session
  deauthenticate(params[:SESSION])
end
function deauthenticate() :: Sessions.Session
  deauthenticate(payload()[:SESSION])
end


"""
    is_authenticated(session) :: Bool
    is_authenticated(params::Dict{Symbol,Any}) :: Bool

Returns `true` if a user id is stored on the session.
"""
function is_authenticated(session::Union{Sessions.Session,Nothing}) :: Bool
  Sessions.isset(session, USER_ID_KEY)
end
function is_authenticated(params::Union{Router.Params,Dict{Symbol,Any}}) :: Bool
  is_authenticated(params[:SESSION])
end
function is_authenticated() :: Bool
  is_authenticated(payload()[:SESSION])
end
const authenticated = is_authenticated


"""
    get_authentication(session) :: Nullable
    get_authentication(params::Dict{Symbol,Any}) :: Nullable

Returns the user id stored on the session, if available.
"""
function get_authentication(session::Sessions.Session) :: Nullable
  Sessions.get(session, USER_ID_KEY)
end
function get_authentication(params::Union{Router.Params,Dict{Symbol,Any}}) :: Nullable
  get_authentication(params[:SESSION])
end
function get_authentication() :: Nullable
  get_authentication(payload()[:SESSION])
end
const authentication = get_authentication


"""
    login(user, session) :: Nullable{Sessions.Session}
    login(user, params::Dict{Symbol,Any}) :: Nullable{Sessions.Session}

Persists on session the id of the user object and returns the session.
"""
function login(user, session::Sessions.Session) :: Nullable{Sessions.Session}
  authenticate(getfield(user, Symbol(user._id)) |> Base.get, session) |> Nullable{Sessions.Session}
end
function login(user, params::Union{Router.Params,Dict{Symbol,Any}}) :: Nullable{Sessions.Session}
  login(user, params[:SESSION])
end
function login(user) :: Nullable{Sessions.Session}
  login(user, payload()[:SESSION])
end


"""
    logout(session) :: Sessions.Session
    logout(params::Dict{Symbol,Any}) :: Sessions.Session

Deletes the id of the user object from the session, effectively logging the user off.
"""
function logout(session::Sessions.Session) :: Sessions.Session
  deauthenticate(session)
end
function logout(params::Union{Router.Params,Dict{Symbol,Any}}) :: Sessions.Session
  logout(params[:SESSION])
end
function logout() :: Sessions.Session
  logout(payload()[:SESSION])
end


"""
    with_authentication(f::Function, fallback::Function, session)
    with_authentication(f::Function, fallback::Function, params::Dict{Symbol,Any})

Invokes `f` only if a user is currently authenticated on the session, `fallback` is invoked otherwise.
"""
function with_authentication(f::Function, fallback::Function, session::Union{Sessions.Session,Nothing})
  if ! is_authenticated(session)
    fallback()
  else
    f()
  end
end
function with_authentication(f::Function, fallback::Function, params::Union{Router.Params,Dict{Symbol,Any}})
  with_authentication(f, fallback, params[:SESSION])
end
function with_authentication(f::Function, fallback::Function)
  with_authentication(f, fallback, payload()[:SESSION])
end


"""
    without_authentication(f::Function, session)
    without_authentication(f::Function, params::Dict{Symbol,Any})

Invokes `f` if there is no user authenticated on the current session.
"""
function without_authentication(f::Function, session::Sessions.Session)
  ! is_authenticated(session) && f()
end
function without_authentication(f::Function, params::Union{Router.Params,Dict{Symbol,Any}})
  without_authentication(f, params[:SESSION])
end
function without_authentication(f::Function)
  without_authentication(f, payload()[:SESSION])
end


"""
"""
function install(dest::String; force = false)
  src = abspath(normpath(joinpath(@__DIR__, "..", Genie.Plugins.FILES_FOLDER)))

  for f in readdir(src)
    isdir(f) || continue
    Genie.Plugins.install(joinpath(src, f), dest, force = force)
  end
end

end
