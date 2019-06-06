module AuthenticationsController

using Genie, Genie.Renderer, Genie.Router, Genie.Sessions, Genie.Helpers
using SearchLight, SearchLight.QueryBuilder
using GenieAuthentication

function show_login()
  html!(:authentications, :show_login, context = @__MODULE__)
end

function login()
  query = (from(User) + where("username = ?", @params(:username)) + where("password = ?", @params(:password))) |> prepare
  try
    user = SearchLight.find_one!!(query...)
    GenieAuthentication.authenticate(user.id, Sessions.session(@params))

    return "Authentication successful"
  catch ex
    flash("Authentication failed")
    redirect_to(:show_login)
  end
end

function logout()
  GenieAuthentication.deauthenticate(Sessions.session(@params))
end

end
