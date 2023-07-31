using Genie

using GenieAuthentication
import ..Main.UserApp.AuthenticationController
import ..Main.UserApp.Users
import SearchLight: findone

export current_user
export current_user_id

current_user() = findone(Users.User, id = get_authentication())
current_user_id() = current_user() === nothing ? nothing : current_user().id

route("/login", AuthenticationController.show_login, named = :show_login)
route("/login", AuthenticationController.login, method = POST, named = :login)
route("/success", AuthenticationController.success, method = GET, named = :success)
route("/logout", AuthenticationController.logout, named = :logout)

#===#

# UNCOMMENT TO ENABLE REGISTRATION ROUTES

# route("/register", AuthenticationController.show_register, named = :show_register)
# route("/register", AuthenticationController.register, method = POST, named = :register)

#===# 

# UNCOMMENT TO ENABLE GOOGLE AUTHENTICATION

route("/auth/google", AuthenticationController.google_auth, named = :google_auth)
route("/auth/google/callback", AuthenticationController.google_callback, named = :google_callback)
route("/pass", AuthenticationController.pass, named = :pass)
route("/fail", AuthenticationController.fail, named = :fail)

