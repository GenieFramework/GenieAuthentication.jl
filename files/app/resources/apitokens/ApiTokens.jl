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
  ValidationRule(:user_id, ApiTokensValidator.not_empty),
  ValidationRule(:name, ApiTokensValidator.unique),
  ValidationRule(:type, ApiTokensValidator.not_empty),
  ValidationRule(:token, ApiTokensValidator.not_empty)
])

end