defmodule Ueberauth.Strategy.Spotify.OAuth do
  @moduledoc """
  OAuth2 for Spotify.

  Add `client_id` and `client_secret` to your configuration:

  config :ueberauth, Ueberauth.Strategy.Spotify.OAuth,
    client_id: System.get_env("SPOTIFY_APP_ID"),
    client_secret: System.get_env("SPOTIFY_APP_SECRET")
    TODO SPOTIFY_REDIRECT_URI
  """

  require Logger

  use OAuth2.Strategy

  @defaults [
    strategy: __MODULE__,
    site: "https://api.spotify.com/v1",
    authorize_url: "https://accounts.spotify.com/authorize",
    token_url: "https://accounts.spotify.com/api/token"
  ]

  @doc """
  Construct a client for requests to Spotify.

  This will be setup automatically for you in `Ueberauth.Strategy.Spotify`.

  These options are only useful for usage outside the normal callback phase of Ueberauth.
  """
  def client(opts \\ []) do
    config = Application.get_env(:ueberauth, Ueberauth.Strategy.Spotify.OAuth)

    opts =
      @defaults
      |> Keyword.merge(config)
      |> Keyword.merge(opts)

    OAuth2.Client.new(opts)
  end

  @doc """
  Provides the authorize url for the request phase of Ueberauth. No need to call this usually.
  """
  def authorize_url!(params \\ [], opts \\ []) do
    opts
    |> client()
    |> OAuth2.Client.authorize_url!(params)
  end

  @spec get_token!(term, keyword) :: OAuth2.AccessToken.t()
  def get_token!(params, opts) do
    opts
    |> client()
    |> OAuth2.Client.get_token!(params)
  end

  # Strategy Callbacks

  def authorize_url(client, params) do
    OAuth2.Strategy.AuthCode.authorize_url(client, params)
  end

  def get_token(client, params, _headers) do
    client
    |> put_header("Accept", "application/json")
    |> put_header(
      "Authorization",
      "Basic " <> encode_credentials(client.client_id, client.client_secret)
    )
    |> OAuth2.Strategy.AuthCode.get_token(params, [])
  end

  # Helper functions

  @spec encode_credentials(String.t(), String.t()) :: String.t()
  def encode_credentials(client_id, client_secret),
    do: (client_id <> ":" <> client_secret) |> Base.encode64()
end
