module Users

using SearchLight, SearchLight.Validation
using ..Main.UserApp.UsersValidator
using GenieAuthentication.SHA
using Sodium

export User, hash_password, verify_password

Base.@kwdef mutable struct User <: AbstractModel
  ### FIELDS
  id::DbId = DbId()
  username::String = ""
  password::String = ""
  name::String = ""
  email::String = ""
end

Validation.validator(u::Type{User}) = ModelValidator([
  ValidationRule(:username, UsersValidator.not_empty),
  ValidationRule(:username, UsersValidator.unique),
  ValidationRule(:password, UsersValidator.not_empty),
  ValidationRule(:email, UsersValidator.not_empty),
  ValidationRule(:email, UsersValidator.unique),
  ValidationRule(:name, UsersValidator.not_empty)
])

const OPSLIMIT = UInt64(Sodium.crypto_pwhash_OPSLIMIT_MODERATE)
const MEMLIMIT = UInt64(Sodium.crypto_pwhash_MEMLIMIT_MODERATE)
const STRBYTES = Sodium.crypto_pwhash_STRBYTES

"""
    hash_password(password::AbstractString)::String

Hash `password` using Argon2id (libsodium’s `crypto_pwhash_str`) and
return a self-contained ASCII string encoding salt, parameters and hash.

# Examples

```jldoctest
julia> using GenieAuthentication.Users

julia> alice_hash = hash_password("correct horse battery staple")
[...]

julia> verify_password(alice_hash, "correct horse battery staple")
true

julia> verify_password(alice_hash, "wrong password")
false
```

See also [`GenieAuthentication.Users.verify_password`](@ref).
"""
function hash_password(password::AbstractString)::String
  buf = Vector{UInt8}(undef, STRBYTES)
  status = Sodium.crypto_pwhash_str(buf, password, UInt64(ncodeunits(password)), OPSLIMIT, MEMLIMIT)
  @assert status == 0 "crypto_pwhash_str failed"
  
  unsafe_string(pointer(buf))
end

"""
    verify_password(stored::AbstractString, password::AbstractString)::Bool

Verify that `password` matches the hash in `stored`. Supports both
Argon2id and legacy SHA hashes. Return `true` if the password is correct.

# Examples

```jldoctest
julia> using GenieAuthentication.Users

julia> alice_hash = hash_password("correct horse battery staple")
[...]

julia> verify_password(alice_hash, "correct horse battery staple")
true

julia> verify_password(alice_hash, "wrong password")
false
```

See also [`GenieAuthentication.Users.hash_password `](@ref).
"""
function verify_password(stored::AbstractString, password::AbstractString)
  if startswith(stored, "\$argon2id\$")
    status = Sodium.crypto_pwhash_str_verify(stored, password, UInt64(ncodeunits(password)))
    return status == 0
  end
  
  stored == sha256(password)
end

end
