using Genie

using GenieAuthentication
import ..Main.UserApp.AuthenticationController
import ..Main.UserApp.Users
import SearchLight: findone

@get("/login", AuthenticationController.show_login; named = :show_login)
@post("/login", AuthenticationController.login; named = :login)
@get("/success", AuthenticationController.success; named = :success)
@get("/logout", AuthenticationController.logout; named = :logout)

#===#

# UNCOMMENT TO ENABLE REGISTRATION ROUTES

# @get("/register", AuthenticationController.show_register; named = :show_register)
# @post("/register", AuthenticationController.register; named = :register)

#===#

include("genie_authentication_hook.jl")