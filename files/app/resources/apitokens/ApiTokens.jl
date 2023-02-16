module ApiTokens

using SearchLight, SearchLight.Validation
using ..Main.UserApp.ApiTokensValidator
using GenieAuthentication.SHA
using Dates

export ApiToken

Base.@kwdef mutable struct ApiToken <: AbstractModel
  ### FIELDS
  id::DbId = DbId()
  user_id::Int = 0
  name::String = ""
  type::String = "basic"
  token::String = ""
  created_at::Date = Dates.now()
end

Validation.validator(u::Type{ApiToken}) = ModelValidator([
  ValidationRule(:user_id, UsersValidator.not_empty),
  ValidationRule(:name, UsersValidator.unique),
  ValidationRule(:type, UsersValidator.not_empty),
  ValidationRule(:token, UsersValidator.not_empty)
])

function hash_password(password::AbstractString)
  sha256(password) |> bytes2hex
end

end