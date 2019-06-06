using Genie, Genie.Router, AuthenticationsController
using Genie.Loggers

route("/login", AuthenticationsController.show_login, named = :show_login)
route("/login", AuthenticationsController.login, method = POST, named = :login)
route("/logout", AuthenticationsController.logout, named = :logout)

Genie.config.session_auto_start = true

log("You can further customise the behaviour of GenieAuthentication at $(@__FILE__)")
