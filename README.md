# GenieAuthentication

Authentication plugin for `Genie.jl`

## Installation

Add the `GenieAuthentication` plugin to your Genie app dependencies.

First load the Genie app's environment:

```bash
$ cd /path/to/your/genie_app

$ bin/repl
```

Next, add the plugin:

```julia
julia> ]

(MyGenieApp) pkg> add https://github.com/GenieFramework/GenieAuthentication.jl#master
```

Once added, we can use it to add its files to the Genie app (required only upon installation):

```julia
julia> using GenieAuthentication

julia> GenieAuthentication.install(@__DIR__)
```

The above command will set up the plugin's files within your Genie app (will potentially add new views, controllers, models, migrations, initializers, etc).

## Usage

The main plugin file should now be found in the `plugins/` folder within your Genie app. It sets up configuration and registers routes.

---
**HEADS UP**

Make sure to comment out the `/register` routes if you don't want to provide user registration features. Otherwise you run the risk of allowing random users to create accounts and expose your application!

---

### Set up the database

The plugin needs DB support to store user data. You will find a `*_create_table_users.jl` migration file within the `db/migrations/` folder. We need to run it:

```julia
julia> using SearchLight

julia> SearchLight.Migration.up("CreateTableUsers")
```

This will create the necessary table.

---
**HEADS UP**

If your app wasn't already set up to work with SearchLight, you need to add SearchLight support first. Please check the Genie documentation on how to do that.

---

### Set up the successful login route

Upon a successful login, the plugin will redirect the user to the `:get_home` route. Please make sure you define the route and name it accordingly, ex: 

```julia
route("/admin", AdminController.index, named = :get_home)
```

If for any reason you can't define the route, you can alternatively edit the code in the `login()` function in `app/resources/authentication/AuthenticationController.jl` and change `:get_home` with your desired route. Editing the controller, however, is not recommended, as future updates might overwrite your changes. 

---

### Forcing authentication

Now that we have a functional authentication system, we can use a Genie controller `before` hook to force authentication. Add this to the controller files which you want placed behind auth:

```julia
before() = authenticated() || throw(ExceptionalResponse(redirect(:show_login)))
```

The `before` hook will automatically be invoked by `Genie.Router` before actually executing the route handler. By throwing an `ExceptionalResponse` `Exception` we force a redirect to the `:show_login` route which displays the login form. 

#### Example

This is how we would limit access to a full module by forcing authentication: 

```julia
module AdminController

using GenieAuthentication, Genie.Renderer, Genie.Exceptions, Genie.Renderer.Html

before() = authenticated() || throw(ExceptionalResponse(redirect(:show_login)))

function index()
  h1("Welcome Admin") |> html
end

end
```

---
**HEADS UP**

If you're throwing an `ExceptionalResponse` as the result of the failed authentication, make sure to also be `using Genie.Exceptions`. 

---

#### Example

The plugin can also be used within functions. 

```julia
module AdminController

using GenieAuthentication, Genie.Renderer, Genie.Exceptions, Genie.Renderer.Html

# This function _can not_ be accessed without authentication
function index()
  authenticated() || throw(ExceptionalResponse(redirect(:show_login)))
  h1("Welcome Admin") |> html
end

# This function _can_ be accessed without authentication
function terms_and_conditions()
  # content here
end

end
```

Or even: 

```julia
using GenieAuthentication

route("/you/shant/pass") do 
  authenticated() || return "Can't touch this!"
  
  "You're welcome!"
end
```

--- 

### Adding a user

You can create a user at the REPL like this (using stronger usernames and passwords though 🙈): 

```julia
julia> u = User(email = "admin@admin", name = "Admin", password = Users.hash_password("admin"), username = "admin")

julia> save!(u)
```

