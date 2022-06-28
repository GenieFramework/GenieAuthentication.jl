# GenieAuthentication

Authentication plugin for `Genie.jl`

## Installation

The `GenieAuthentication.jl` package is an authentication plugin for `Genie.jl`, the highly productive Julia web framework.
As such, it requires installation within the environment of a `Genie.jl` MVC application, allowing the plugin to install
its files (which include models, controllers, database migrations, plugins, and other files).

### Load your `Genie.jl` app

First load the `Genie.jl` application, for example using

```bash
$> cd /path/to/your/genie_app

$> ./bin/repl
```

Alternatively, you can create a new `Genie.jl` MVC application (`SearchLight.jl` ORM support is required in order to store
the user accounts into the database). If you are not sure how to do that, please follow the documentation for `Genie.jl`,
for example at <https://genieframework.github.io/Genie.jl/dev/tutorials/4-1--Developing_MVC_Web_Apps.html>.

### Add the plugin

Next, add the plugin:

```julia
julia> ]

(MyGenieApp) pkg> add GenieAuthentication
```

Once added, we can use its `install` function to add its files to the `Genie.jl` app (required only upon installation):

```julia
julia> using GenieAuthentication

julia> GenieAuthentication.install(@__DIR__)
```

The above command will set up the plugin's files within your `Genie.jl` app (will potentially add new views, controllers, models, migrations, initializers, etc).

## Usage

The main plugin file should now be found in the `plugins/` folder within your `Genie.jl` app. It sets up configuration and registers routes.

---
**HEADS UP**

Make sure to uncomment out the `/register` routes in `plugins/genie_authentication.jl` if you want to provide user registration features.
They are disabled by default in order to eliminate the risk of accidentally allowing random users to create accounts and expose your application.

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

If your app wasn't already set up to work with `SearchLight.jl`, you need to add `SearchLight.jl` support first.
Please check the `Genie.jl` documentation on how to do that, for example at <https://genieframework.github.io/Genie.jl/dev/tutorials/4-1--Developing_MVC_Web_Apps.html#Connecting-to-the-database>. This includes setting up a `db/connection.yml` and an empty migration table with `create_migrations_table` if it has not already been done.

---

### Set up the successful login route

Upon a successful login, the plugin will redirect the user to the `:success` route, which invokes `AuthenticationController.success`.

---

### Enforcing authentication

Now that we have a functional authentication system, there are two ways of enforcing authentication.

#### `@authenticated!`

The `@authenticated!` macro will enforce authentication - meaning that it will check if a user is authenticated, and if not,
it will automatically throw an `ExceptionalResponse` `Exception` and force a redirect to the `:show_login` route which displays the login form.

We can use this anywhere in our route handling code, for example within routes:

```julia
# routes.jl
using GenieAuthentication

route("/protected") do; @authenticated!
  # this code is only accessible for authenticated users
end
```

Or within handler functions inside controllers:

```julia
# routes.jl
route("/protected", ProtectedController.secret)
```

```julia
# ProtectedController.jl
using GenieAuthentication

function secret()
  @authenticated!

  # this code is only accessible for authenticated users
end
```

---
**HEADS UP**

If you're throwing an `ExceptionalResponse` as the result of the failed authentication, make sure to also be `using Genie.Exceptions`.

---

#### `authenticated()`

In addition to the imperative style of the `@authenticated!` macro, we can also use the `authenticated()` function which
returns a `bool` indicated if a user is currently authenticated.

It is especially used for adding dynamic UI elements based on the state of the authentication:

```html
<div class="row align-items-center">
  <div class="col col-12 text-center">
    <% if ! authenticated() %>
    <a href="/login" class="btn btn-light btn-lg" style="color: #fff;">Login</a>
    <% end %>
  </div>
</div>
```

We can also use it to mimic the behaviour of `@authenticated!`:

```julia
using GenieAuthentication

# This function _can not_ be accessed without authentication
function index()
  authenticated() || throw(ExceptionalResponse(redirect(:show_login)))

  h1("Welcome Admin") |> html
end
```

Or to perform custom actions:

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
julia> using Users

julia> u = User(email = "admin@admin", name = "Admin", password = Users.hash_password("admin"), username = "admin")

julia> save!(u)
```
---

### Get current user information

If the user was authenticated, check first with `authenticated()`, you can obtain the current user information with `current_user()`.

```julia
using GenieAuthentication

route("/your/email") do
  authenticated() || return "Can't get it!"
  user = current_user()
  user.email
end
```
