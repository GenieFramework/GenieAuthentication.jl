using Genie, Genie.Router, AuthenticationController

route("/login", AuthenticationController.show_login, named = :show_login)
route("/login", AuthenticationController.login, method = POST, named = :login)
route("/logout", AuthenticationController.logout, named = :logout)
route("/register", AuthenticationController.show_register, named = :show_register)
route("/register", AuthenticationController.register, method = POST, named = :register)

Genie.config.session_auto_start = true