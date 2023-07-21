module AuthenticationController

using Genie, Genie.Renderer, Genie.Renderer.Html, Genie.Context
using SearchLight
using Logging

using ..Main.UserApp.Users
using ..Main.UserApp.GenieAuthenticationViewHelper

using GenieAuthentication
using GenieAuthentication.GenieSession
using GenieAuthentication.GenieSession.Flash
using GenieAuthentication.GenieSessionCookieSession


function show_login(params::Params)
  html(:authentication, :login; params, context = @__MODULE__)
end

function login(params::Params)
  try
    user = haskey(params, :token) ?
            findone(User, token = params[:token]) :
            findone(User, username = params[:post][:username], password = Users.hash_password(params[:post][:password]))

    authenticate(params, user.id)

    redirect(:success)
  catch ex
    flash(params, "Authentication failed! ")

    redirect(:show_login)
  end
end

function success(params::Params)
  html(:authentication, :success; context = @__MODULE__, params)
end

function logout(params::Params)
  deauthenticate(params)

  flash(params, "Good bye! ")

  redirect(:show_login)
end

function show_register(params::Params)
  html(:authentication, :register; context = @__MODULE__, params)
end

function register(params::Params)
  try
    user = User(username  = params[:post][:username],
                password  = params[:post][:password] |> Users.hash_password,
                name      = params[:post][:name],
                email     = params[:post][:email],
                token     = haskey(params[:post], :token) ? params[:post][:token] : Genie.Secrets.secret()) |> save!

    authenticate(params, user.id)
  catch ex
    if hasfield(typeof(ex), :msg)
      flash(params, ex.msg)
    else
      flash(params, string(ex))
    end

    redirect(:register)
  end

  redirect(:success)
end

end