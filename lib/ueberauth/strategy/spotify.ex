defmodule Ueberauth.Strategy.Spotify do
  @moduledoc """
  Spotify Strategy for Überauth.
  """

  use Ueberauth.Strategy, uid_field: :uid,
                          default_scope: "user-read-email"

  alias Ueberauth.Auth.Info

  @doc """
  Handles initial request for Spotify authentication.
  """
  def handle_request!(conn) do
    scopes = conn.params["scope"] || option(conn, :default_scope)
    opts = [ scope: scopes ]
    if conn.params["state"], do: opts = Keyword.put(opts, :state, conn.params["state"])
    if conn.params["show_dialog"], do: opts = Keyword.put(opts, :show_dialog, conn.params["show_dialog"])
    opts = Keyword.put(opts, :redirect_uri, callback_url(conn))
    redirect!(conn, Ueberauth.Strategy.Spotify.OAuth.authorize_url!(opts))
  end

  @doc """
  Handles the callback from Spotify.
  """
  def handle_callback!(%Plug.Conn{ params: %{ "code" => code } } = conn) do
    opts = [redirect_uri: callback_url(conn)]
    token = Ueberauth.Strategy.Spotify.OAuth.get_token!([code: code], opts)

    if token.access_token == nil do
      set_errors!(conn, [error(token.other_params["error"], token.other_params["error_description"])])
    else
      fetch_user(conn, token)
    end
  end

  @doc """
  Handles the error callback from Spotify
  """
  def handle_callback!(%Plug.Conn{ params: %{ "error" => error } } = conn) do
    set_errors!(conn, [error("error", error)])
  end

  defp fetch_user(conn, token) do
    case OAuth2.AccessToken.get(token, "/me") do
      { :ok, %OAuth2.Response{status_code: 404, body: _body}} ->
        set_errors!(conn, [error("OAuth2", "404 - not found")])
      { :ok, %OAuth2.Response{status_code: 401, body: _body}} ->
        set_errors!(conn, [error("token", "unauthorized")])
      { :ok, %OAuth2.Response{status_code: status_code, body: user} } when status_code in 200..399 ->
        put_private(conn, :spotify_user, user)
      { :error, %OAuth2.Error{reason: reason} } ->
        set_errors!(conn, [error("OAuth2", reason)])
    end
  end

  @doc false
  def info(conn) do
    user = conn.private.spotify_user
    %Info{
      name: user["display_name"],
      nickname: user["id"],
      email: user["email"],
      image: hd(user["images"])["url"]
    }
  end

  defp option(conn, key) do
    Dict.get(options(conn), key, Dict.get(default_options, key))
  end

end
