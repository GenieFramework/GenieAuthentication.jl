"""
Functionality for authenticating Genie users.
"""
module GenieAuthentication

import Genie, SearchLight

export authenticate, deauthenticate, is_authenticated, get_authentication, authenticated
export login, logout, with_authentication, without_authentication

const USER_ID_KEY = :__auth_user_id


"""
Stores the user id on the session.
"""
function authenticate(user_id::Any, session::Genie.Sessions.Session) :: Genie.Sessions.Session
  Genie.Sessions.set!(session, USER_ID_KEY, user_id)
end
function authenticate(user::SearchLight.DbId, session::Genie.Sessions.Session)
  authenticate(Int(user.value), session)
end
function authenticate(user_id::Union{String,Symbol,Int,SearchLight.DbId}, params::Dict{Symbol,Any} = Genie.Requests.payload()) :: Genie.Sessions.Session
  authenticate(user_id, params[:SESSION])
end


"""
    deauthenticate(session) :: Sessions.Session
    deauthenticate(params::Dict{Symbol,Any}) :: Sessions.Session

Removes the user id from the session.
"""
function deauthenticate(session::Genie.Sessions.Session) :: Genie.Sessions.Session
  Genie.Sessions.unset!(session, USER_ID_KEY)
end
function deauthenticate(params::Dict{Symbol,Any} = Genie.Requests.payload()) :: Genie.Sessions.Session
  deauthenticate(params[:SESSION])
end


"""
    is_authenticated(session) :: Bool
    is_authenticated(params::Dict{Symbol,Any}) :: Bool

Returns `true` if a user id is stored on the session.
"""
function is_authenticated(session::Union{Genie.Sessions.Session,Nothing}) :: Bool
  Genie.Sessions.isset(session, USER_ID_KEY)
end
function is_authenticated(params::Dict{Symbol,Any} = Genie.Requests.payload()) :: Bool
  is_authenticated(params[:SESSION])
end

const authenticated = is_authenticated


"""
    get_authentication(session) :: Nullable
    get_authentication(params::Dict{Symbol,Any}) :: Nullable

Returns the user id stored on the session, if available.
"""
function get_authentication(session::Genie.Sessions.Session) :: Union{Nothing,Any}
  Genie.Sessions.get(session, USER_ID_KEY)
end
function get_authentication(params::Dict{Symbol,Any} = Genie.Requests.payload()) :: Union{Nothing,Any}
  get_authentication(params[:SESSION])
end

const authentication = get_authentication


"""
    login(user, session) :: Nullable{Sessions.Session}
    login(user, params::Dict{Symbol,Any}) :: Nullable{Sessions.Session}

Persists on session the id of the user object and returns the session.
"""
function login(user, session::Genie.Sessions.Session) :: Union{Nothing,Genie.Sessions.Session}
  authenticate(getfield(user, Symbol(user._id)), session)
end
function login(user, params::Dict{Symbol,Any} = Genie.Requests.payload()) :: Union{Nothing,Genie.Sessions.Session}
  login(user, params[:SESSION])
end


"""
    logout(session) :: Sessions.Session
    logout(params::Dict{Symbol,Any}) :: Sessions.Session

Deletes the id of the user object from the session, effectively logging the user off.
"""
function logout(session::Genie.Sessions.Session) :: Genie.Sessions.Session
  deauthenticate(session)
end
function logout(params::Dict{Symbol,Any} = Genie.Requests.payload()) :: Genie.Sessions.Session
  logout(params[:SESSION])
end


"""
    with_authentication(f::Function, fallback::Function, session)
    with_authentication(f::Function, fallback::Function, params::Dict{Symbol,Any})

Invokes `f` only if a user is currently authenticated on the session, `fallback` is invoked otherwise.
"""
function with_authentication(f::Function, fallback::Function, session::Union{Genie.Sessions.Session,Nothing})
  if ! is_authenticated(session)
    fallback()
  else
    f()
  end
end
function with_authentication(f::Function, fallback::Function, params::Dict{Symbol,Any} = Genie.Requests.payload())
  with_authentication(f, fallback, params[:SESSION])
end


"""
    without_authentication(f::Function, session)
    without_authentication(f::Function, params::Dict{Symbol,Any})

Invokes `f` if there is no user authenticated on the current session.
"""
function without_authentication(f::Function, session::Genie.Sessions.Session)
  ! is_authenticated(session) && f()
end
function without_authentication(f::Function, params::Dict{Symbol,Any} = Genie.Requests.payload())
  without_authentication(f, params[:SESSION])
end


"""
"""
function install(dest::String; force = false, debug = false)
  src = abspath(normpath(joinpath(pathof(@__MODULE__) |> dirname, "..", Genie.Plugins.FILES_FOLDER)))
  debug && @info "Preparing to install from $src into $dest"
  debug && @info "Found these files to install $(readdir(src))"

  for f in readdir(src)
    isdir(f) || continue
    debug && "Installing from $(joinpath(src, f))"
    Genie.Plugins.install(joinpath(src, f), dest, force = force)
  end
end

end
