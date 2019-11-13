module AuthenticationController

using Genie, Genie.Renderer, Genie.Router, Genie.Sessions, Genie.Flash
using ViewHelper
using SearchLight
using GenieAuthentication
using Users

Genie.config.session_auto_start = true

function show_login()
  html(:authentication, :login, context = @__MODULE__)
end

function login()
  try
    user = SearchLight.findone(User, username = @params(:username), password = Users.hash_password(@params(:password)))
    GenieAuthentication.authenticate(user.id, Sessions.session(@params))

    redirect(:get_home)
  catch ex
    flash("Authentication failed")

    redirect(:show_login)
  end
end

function logout()
  GenieAuthentication.deauthenticate(Sessions.session(@params))

  flash("Good bye! ")

  redirect(:show_login)
end

function show_register()
  html(:authentication, :register, context = @__MODULE__)
end

function register()
  try
    user = SearchLight.save!!(User( username  = @params(:username),
                                    password  = @params(:password) |> Users.hash_password,
                                    name      = @params(:name),
                                    email     = @params(:email)))

    GenieAuthentication.authenticate(user.id, Sessions.session(@params))
    "Registration successful"
  catch ex
    flash(ex.msg)

    redirect(:show_register)
  end
end

end