defmodule Ueberauth.Strategy.Spotify do
  @moduledoc """
  Spotify Strategy for Überauth.
  """

  use Ueberauth.Strategy,
    uid_field: :uid,
    default_scope: "user-read-email",
    ignores_csrf_attack: false

  alias Ueberauth.Auth.Info
  alias Ueberauth.Auth.Credentials
  alias Ueberauth.Auth.Extra

  @doc """
  Handles initial redirect to the Spotify authentication page.

  To customize the scope (permissions) that are requested by Spotify include them as part of your url:

      "/auth/spotify?scope=user-read-email,user-read-privatet"

  You can also include a `state` param that Spotify will return to you.
  """
  def handle_request!(conn) do
    scopes = conn.params["scope"] || option(conn, :default_scope)
    state = Map.get(conn.params, "state", conn.private[:ueberauth_state_param])

    opts = [
      scope: scopes,
      state: state,
      show_dialog: Map.get(conn.params, "show_dialog", nil),
      redirect_uri: callback_url(conn)
    ]

    redirect!(conn, Ueberauth.Strategy.Spotify.OAuth.authorize_url!(opts))
  end

  @doc """
  Handles the callback from Spotify. When there is a failure from Spotify the failure is included in the
  `ueberauth_failure` struct. Otherwise the information returned from Spotify is returned in the `Ueberauth.Auth` struct.
  """
  def handle_callback!(%Plug.Conn{params: %{"code" => code}} = conn) do
    options = [redirect_uri: callback_url(conn)]

    token = Ueberauth.Strategy.Spotify.OAuth.get_token!([code: code], options)

    if token.access_token == nil do
      set_errors!(conn, [
        error(
          token.other_params["error"],
          token.other_params["error_description"]
        )
      ])
    else
      fetch_user(conn, token)
    end
  end

  @doc """
  Handles the error callback from Spotify
  """
  def handle_callback!(%Plug.Conn{params: %{"error" => error}} = conn) do
    set_errors!(conn, [error("error", error)])
  end

  defp fetch_user(conn, token) do
    conn = put_private(conn, :spotify_token, token)

    case Ueberauth.Strategy.Spotify.OAuth.get(token, "/me") do
      {:ok, %OAuth2.Response{status_code: 400, body: _body}} ->
        set_errors!(conn, [error("OAuth2", "400 - bad request")])

      {:ok, %OAuth2.Response{status_code: 404, body: _body}} ->
        set_errors!(conn, [error("OAuth2", "404 - not found")])

      {:ok, %OAuth2.Response{status_code: 401, body: _body}} ->
        set_errors!(conn, [error("token", "unauthorized")])

      {:ok, %OAuth2.Response{status_code: status_code, body: user}}
      when status_code in 200..399 ->
        put_private(conn, :spotify_user, user)

      {:error, %OAuth2.Error{reason: reason}} ->
        set_errors!(conn, [error("OAuth2", reason)])
    end
  end

  @doc """
  Fetches the fields to populate the info section of the `Ueberauth.Auth` struct.
  """
  def info(conn) do
    user = conn.private.spotify_user

    %Info{
      name: user["display_name"],
      nickname: user["id"],
      email: user["email"],
      image: List.first(user["images"])["url"],
      urls: %{external: user["external_urls"]["spotify"], spotify: user["uri"]},
      location: user["country"]
    }
  end

  def extra(conn) do
    %Extra{
      raw_info: %{
        token: conn.private.spotify_token,
        user: conn.private.spotify_user
      }
    }
  end

  @doc """
  Includes the credentials from the Spotify response.
  """
  def credentials(conn) do
    token = conn.private.spotify_token
    scopes = token.other_params["scope"] || ""
    scopes = String.split(scopes, ",")

    %Credentials{
      token: token.access_token,
      refresh_token: token.refresh_token,
      expires_at: token.expires_at,
      token_type: token.token_type,
      expires: !!token.expires_at,
      scopes: scopes
    }
  end

  defp option(conn, key) do
    options(conn)
    |> Keyword.get(key, Keyword.get(default_options(), key))
  end
end
