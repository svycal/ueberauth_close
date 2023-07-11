# Überauth Close

> Close.io OAuth2 strategy for Überauth.

## Installation

1. Create an OAuth app in your Close.io Developer settings.

1. Add `:ueberauth_close` to your list of dependencies in `mix.exs`:

   ```elixir
   def deps do
     [{:ueberauth_close, "~> 0.1.0"}]
   end
   ```

1. Add Close.io to your Überauth configuration:

   ```elixir
   config :ueberauth, Ueberauth,
     providers: [
       close: {Ueberauth.Strategy.Close, []}
     ]
   ```

1. Update your provider configuration:

   To read client ID/secret from the environment
   variables at compile time:

   ```elixir
   config :ueberauth, Ueberauth.Strategy.Close.OAuth,
     client_id: System.get_env("CLOSE_CLIENT_ID"),
     client_secret: System.get_env("CLOSE_CLIENT_SECRET")
   ```

   To read client ID/secret from the environment
   variables at run time:

   ```elixir
   config :ueberauth, Ueberauth.Strategy.Close.OAuth,
     client_id: {System, :get_env, ["CLOSE_CLIENT_ID"]},
     client_secret: {System, :get_env, ["CLOSE_CLIENT_SECRET"]}
   ```

1. Include the Überauth plug in your controller:

   ```elixir
   defmodule MyApp.AuthController do
     use MyApp.Web, :controller
     plug Ueberauth
     ...
   end
   ```

1. Create the request and callback routes if you haven't already:

   ```elixir
   scope "/auth", MyApp do
     pipe_through :browser

     get "/:provider", AuthController, :request
     get "/:provider/callback", AuthController, :callback
   end
   ```

1. Your controller needs to implement callbacks to deal with `Ueberauth.Auth` and `Ueberauth.Failure` responses.

For an example implementation see the [Überauth Example](https://github.com/ueberauth/ueberauth_example) application.

## Calling

Depending on the configured url you can initiate the request through:

    /auth/close

## License

Please see [LICENSE](https://github.com/svycal/ueberauth_close/blob/main/LICENSE.md) for licensing details.
