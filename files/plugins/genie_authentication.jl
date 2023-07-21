using Genie

using GenieAuthentication
import ..Main.UserApp.AuthenticationController
import ..Main.UserApp.Users
import SearchLight: findone

export current_user
export current_user_id

current_user(params::Params) = findone(Users.User, id = get_authentication(params))
current_user_id(params::Params) = current_user(params) === nothing ? nothing : current_user(params).id

@get("/login", AuthenticationController.show_login; named = :show_login)
@post("/login", AuthenticationController.login; named = :login)
@get("/success", AuthenticationController.success; named = :success)
@get("/logout", AuthenticationController.logout; named = :logout)

#===#

# UNCOMMENT TO ENABLE REGISTRATION ROUTES

# @get("/register", AuthenticationController.show_register; named = :show_register)
# @post("/register", AuthenticationController.register; named = :register)