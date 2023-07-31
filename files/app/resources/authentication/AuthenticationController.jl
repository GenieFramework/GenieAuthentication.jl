module AuthenticationController

using Genie, Genie.Renderer, Genie.Renderer.Html, Genie.HTTPUtils.HTTP, Genie.Renderers.Json.JSON3
using SearchLight
using Logging

using ..Main.UserApp.Users
using ..Main.UserApp.GenieAuthenticationViewHelper

using GenieAuthentication
using GenieAuthentication.GenieSession
using GenieAuthentication.GenieSession.Flash
using GenieAuthentication.GenieSessionFileSession

function generate_query_string(params::Dict{String,String})
  return join(["$k=$(HTTP.escapeuri(v))" for (k, v) in params], '&')
end

function show_login()
  html(:authentication, :login, context = @__MODULE__)
end

function login()
  try
    user = findone(User, username = params(:username), password = Users.hash_password(params(:password)))
    authenticate(user.id, GenieSession.session(params()))

    redirect(:success)
  catch ex
    flash("Authentication failed! ")

    redirect(:show_login)
  end
end

function success()
  html(:authentication, :success, context = @__MODULE__)
end

function logout()
  deauthenticate(GenieSession.session(params()))

  flash("Good bye! ")

  redirect(:show_login)
end

function show_register()
  html(:authentication, :register, context = @__MODULE__)
end

function register()
  try
    user = User(username  = params(:username),
                password  = params(:password) |> Users.hash_password,
                name      = params(:name),
                email     = params(:email)) |> save!

    authenticate(user.id, GenieSession.session(params()))

    "Registration successful"
  catch ex
    @error ex

    if hasfield(typeof(ex), :msg)
      flash(ex.msg)
    else
      flash(string(ex))
    end

    redirect(:show_register)
  end
end

function google_auth()
  authUrl = "https://accounts.google.com/o/oauth2/v2/auth"
  params = Dict(
      "client_id" => ENV["GOOGLE_CLIENT_ID"],
      "redirect_uri" => ENV["REDIRECT_URI"],
      "response_type" => "code",
      "scope" => "https://www.googleapis.com/auth/userinfo.profile",
      "access_type" => "offline",
      "include_granted_scopes" => "true",
      "state" => "pass-through value"
  )
  query_string = generate_query_string(params)

  Genie.Renderer.redirect(authUrl * "?" * query_string)
end

function google_callback()
  authUrl = "https://oauth2.googleapis.com/token"
  code = params(:code, nothing)

  headers = ["Content-Type" => "application/x-www-form-urlencoded"]

  data = Dict(
      "code" => code,
      "client_id" => ENV["GOOGLE_CLIENT_ID"],
      "client_secret" => ENV["GOOGLE_CLIENT_SECRET"],
      "redirect_uri" => ENV["REDIRECT_URI"],
      "grant_type" => "authorization_code"
  )

  try
      query_string = generate_query_string(data)
      response = HTTP.post(authUrl, headers, query_string)
      access_token = JSON3.read(String(response.body), Dict)["access_token"]

      user_obj = HTTP.get(
          "https://www.googleapis.com/oauth2/v1/userinfo", 
          ["Authorization" => "Bearer $access_token"]
      )
      user_info = JSON3.read(String(user_obj.body), Dict)

      username = user_info["email"]  # or some other unique identifier
      password = Users.hash_password(randstring(20))  # generate a random password
      name = user_info["name"]
      email = user_info["email"]

      user = User(username = username,
                  password = password, 
                  name = name, 
                  email = email, 
                  token = access_token) |> save!
    
      #TODO: Authenticate show register
      #TODO: "Registration successful"
  catch ex
      @info ex
      #TODO: FAILED REGISTRATION
  end
end

function pass()
  return "pass"
end

function fail()
  return "fail"
end

end