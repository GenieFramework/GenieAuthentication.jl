module GenieAuthenticationViewHelper

using GenieAuthentication.GenieSession
using GenieAuthentication.GenieSessionCookieSession
using GenieAuthentication.GenieSession.Flash

export output_flash

function output_flash(params) :: String
  flash_has_message(params) ? """<div class="form-group alert alert-info">$(params[:flash])</div>""" : ""
end

end