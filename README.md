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

### Forcing authentication

Now that we have a functional authentication system, we can use a Genie controller `before` hook to force authentication. Add this to the controller files which you want placed behind auth:

```julia
before() = authenticated() || throw(ExceptionalResponse(redirect(:show_login)))
```

The `before` hook will automatically be invoked by `Genie.Router` before actually executing the route handler. By throwing an `ExceptionalResponse` exception we fore a redirect to the `:show_login` route which displays the login form.

