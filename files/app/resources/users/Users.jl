module Users

using SearchLight, SearchLight.Validation, UsersValidator
using SHA

export User

mutable struct User <: AbstractModel
  ### INTERNALS
  _table_name::String
  _id::String
  _serializable::Vector{Symbol}

  ### FIELDS
  id::DbId
  username::String
  password::String
  name::String
  email::String

  ### VALIDATION
  validator::ModelValidator

  ### CALLBACKS
  # before_save::Function
  # after_save::Function
  # on_save::Function
  # on_find::Function
  # after_find::Function

  ### SCOPES
  # scopes::Dict{Symbol,Vector{SearchLight.SQLWhereEntity}}

  ### constructor
  User(;
    ### FIELDS
    id = DbId(),
    username = "",
    password = "",
    name = "",
    email = "",

    ### VALIDATION
    validator = ModelValidator([
      ValidationRule(:username, UsersValidator.not_empty),
      ValidationRule(:username, UsersValidator.unique),
      ValidationRule(:password, UsersValidator.not_empty),
      ValidationRule(:email,    UsersValidator.not_empty),
      ValidationRule(:email,    UsersValidator.unique),
      ValidationRule(:name,     UsersValidator.not_empty)
    ]),

    ### CALLBACKS
    # before_save = (m::User) -> begin
    #   @info "Before save"
    # end,
    # after_save = (m::User) -> begin
    #   @info "After save"
    # end,
    # on_save = (m::User, field::Symbol, value::Any) -> begin
    #   @info "On save"
    # end,
    # on_find = (m::User, field::Symbol, value::Any) -> begin
    #   @info "On find"
    # end,
    # after_find = (m::User) -> begin
    #   @info "After find"
    # end,

    ### SCOPES
    # scopes = Dict{Symbol,Vector{SearchLight.SQLWhereEntity}}()

  ) = new("users", "id", Symbol[],                                                      ### INTERNALS
          id, username, password, name, email,                                          ### FIELDS
          validator,                                                                    ### VALIDATION
          # before_save, after_save, on_save, on_find, after_find                       ### CALLBACKS
          # scopes                                                                      ### SCOPES
          )
end

function hash_password(password::String)
  sha256(password) |> bytes2hex
end

end