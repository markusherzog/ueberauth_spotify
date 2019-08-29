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
    {serializers, config} =
      :ueberauth
      |> Application.fetch_env!(Ueberauth.Strategy.Spotify.OAuth)
      |> check_config_key_exists(:client_id)
      |> check_config_key_exists(:client_secret)
      |> Keyword.pop(:serializers, [{"application/json", Ueberauth.json_library()}])

    client_opts =
      @defaults
      |> Keyword.merge(config)
      |> Keyword.merge(opts)

    client = OAuth2.Client.new(client_opts)

    Enum.reduce(serializers, client, fn {mimetype, module}, client ->
      OAuth2.Client.put_serializer(client, mimetype, module)
    end)
  end

  @doc """
  Provides the authorize url for the request phase of Ueberauth. No need to call this usually.
  """
  def authorize_url!(params \\ [], opts \\ []) do
    opts
    |> client()
    |> OAuth2.Client.authorize_url!(params)
  end

  def get(token, url, headers \\ [], opts \\ []) do
    [token: token]
    |> client()
    |> OAuth2.Client.get(url, headers, opts)
  end

  @spec get_token!(term, keyword) :: OAuth2.AccessToken.t()
  def get_token!(params \\ [], options \\ []) do
    client =
      options
      |> client()
      |> OAuth2.Client.get_token!(params)

    client.token
  end

  # Strategy Callbacks

  def authorize_url(client, params) do
    OAuth2.Strategy.AuthCode.authorize_url(client, params)
  end

  def get_token(client, params, headers) do
    client
    |> put_header("Accept", "application/json")
    |> put_header(
      "Authorization",
      "Basic " <> encode_credentials(client.client_id, client.client_secret)
    )
    |> OAuth2.Strategy.AuthCode.get_token(params, headers)
  end

  # Helper functions

  @spec encode_credentials(String.t(), String.t()) :: String.t()
  def encode_credentials(client_id, client_secret),
    do: (client_id <> ":" <> client_secret) |> Base.encode64()

  defp check_config_key_exists(config, key) when is_list(config) do
    unless Keyword.has_key?(config, key) do
      raise "#{inspect(key)} missing from config :ueberauth, Ueberauth.Strategy.Spotify"
    end

    config
  end

  defp check_config_key_exists(_, _) do
    raise "Config :ueberauth, Ueberauth.Strategy.Spotify is not a keyword list, as expected"
  end
end
