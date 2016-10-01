# Überauth Spotify

> Spotify OAuth2 strategy for [Überauth](https://github.com/ueberauth).

## Installation

1. Setup your application at the [Spotify Developer Console]().

1. Add `:ueberauth_spotify` to your list of dependencies in `mix.exs`:

    ```elixir
    def deps do
      [{:ueberauth_spotify, "0.0.2"}]
    end
    ```

1. Fetch the dependencies
    ```elixir
    mix deps.get
    ```

1. Add the strategy to your applications in `mix.exs`::

    ```elixir
    def application do
      [applications: [:ueberauth_spotify]]
    end
    ```

1. Add Spotify to your Überauth configuration in `config/config.exs`::

    ```elixir
    config :ueberauth, Ueberauth,
      providers: [
        spotify: {Ueberauth.Strategy.Spotify, []}
      ]
    ```

1.  Update your provider configuration in `config/[dev|test|prod].exs`:

    ```elixir
    config :ueberauth, Ueberauth.Strategy.Spotify.OAuth,
      client_id: System.get_env("SPOTIFY_CLIENT_ID"),
      client_secret: System.get_env("SPOTIFY_CLIENT_SECRET")
    ```

1.  Include the Überauth plug in your controller:

    ```elixir
    defmodule MyApp.AuthController do
      use MyApp.Web, :controller
      plug Ueberauth
      ...
    end
    ```

1.  Create the request and callback routes if you haven't already:

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

Depending on the configured url you can initial the request through:

    /auth/spotify

Or with options:

    /auth/spotify?scope=...&show_dialog=true

By default the requested scope is "user-read-email". Scope can be configured either explicitly as a `scope` query value on the request path or in your configuration:

```elixir
config :ueberauth, Ueberauth,
  providers: [
    spotify: {Ueberauth.Strategy.Spotify, [default_scope: "user-read-email,user-read-private"]}
  ]
```

## License

Please see [LICENSE](https://github.com/markusherzog/ueberauth_spotify/blob/master/LICENSE) for licensing details.
