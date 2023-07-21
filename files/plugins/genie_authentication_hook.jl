function authuser(req, res, params)
  user = if isbearerauthrequest(params)
    findone(Users.User, token = params[:token])
  elseif isbasicauthrequest(params)
    findone(Users.User, username = params[:username], password = Users.hash_password(params[:password]))
  elseif isauthenticated(params)
    findone(Users.User, id = get_authentication(params))
  else
    nothing
  end

  params.collection = ImmutableDict(params.collection, :authuser => user)

  req, res, params
end

authuser in Genie.Router.pre_match_hooks || push!(Genie.Router.pre_match_hooks, authuser)