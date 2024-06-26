defmodule Ueberauth.Strategy.Close do
  @moduledoc """
  Close Strategy for Überauth.
  """

  use Ueberauth.Strategy,
    default_scope: "all.full_access offline_access",
    oauth2_module: Ueberauth.Strategy.Close.OAuth

  require Logger

  alias Ueberauth.Auth.Credentials
  alias Ueberauth.Auth.Extra

  @doc """
  Handles the initial redirect to the Close authentication page.
  """
  def handle_request!(conn) do
    params =
      []
      |> with_scope(conn)
      |> with_state_param(conn)

    opts = [redirect_uri: callback_url(conn)]
    module = option(conn, :oauth2_module)

    conn
    |> redirect!(module.authorize_url!(params, opts))
  end

  @doc """
  Handles the callback from Close.
  """
  def handle_callback!(%Plug.Conn{params: %{"code" => code}} = conn) do
    params = [
      grant_type: "authorization_code",
      code: code,
      redirect_uri: callback_url(conn)
    ]

    module = option(conn, :oauth2_module)
    opts = [redirect_uri: callback_url(conn)]

    case module.get_token(params, opts) do
      {:ok, %{token: %OAuth2.AccessToken{access_token: "" <> _string} = token}} ->
        conn
        |> put_private(:close_token, token)

      # |> fetch_user()

      err ->
        handle_failure(conn, err)
    end
  end

  @doc false
  def handle_callback!(conn) do
    set_errors!(conn, [error("missing_code", "No code received")])
  end

  @doc false
  def handle_cleanup!(conn) do
    conn
    |> put_private(:close_token, nil)
  end

  @doc """
  Includes the credentials from the Close response.
  """

  def credentials(conn) do
    token = conn.private.close_token
    scope_string = token.other_params["scope"] || ""
    scopes = String.split(scope_string, " ")

    %Credentials{
      expires: !!token.expires_at,
      expires_at: token.expires_at,
      scopes: scopes,
      token_type: Map.get(token, :token_type),
      refresh_token: token.refresh_token,
      token: token.access_token,
      other: token.other_params
    }
  end

  # @doc """
  # Fetches the fields to populate the info section of the `Ueberauth.Auth` struct.
  # """
  def info(conn) do
    # Fetch the data from https://api.close.com/api/v1/me/ using the access token.
    # This gives extra data about the user.
    access_token = conn.private.close_token.access_token
    url = "https://api.close.com/api/v1/me/"

    # Set up the Tesla client
    client =
      Tesla.client([
        {Tesla.Middleware.Headers, [{"Authorization", "Bearer #{access_token}"}]}
      ])

    # Make the request
    response = client |> Tesla.get(url)

    # Parse the response
    case response do
      {:ok, %{status: 200, body: body}} ->
        {:ok, body} = Jason.decode(body)

        %Ueberauth.Auth.Info{
          first_name: body |> Map.get("first_name"),
          last_name: body |> Map.get("last_name"),
          email: body |> Map.get("email"),
          image: body |> Map.get("image"),
          phone: body |> Map.get("phone")
        }

      _ ->
        Logger.warning("Failed to fetch user info from Close API: #{inspect(response)}")
        %Ueberauth.Auth.Info{}
    end
  end

  @doc """
  Stores the raw information (e.g. account/user ID) obtained from the Close callback.
  """
  def extra(conn) do
    token = conn.private.close_token

    %Extra{
      raw_info: token.other_params
    }
  end

  # Request failure handling

  defp handle_failure(conn, {:error, %OAuth2.Error{reason: reason}}) do
    set_errors!(conn, [error("OAuth2", reason)])
  end

  defp handle_failure(conn, {:error, %OAuth2.Response{status_code: 401}}) do
    set_errors!(conn, [error("token", "unauthorized")])
  end

  defp handle_failure(
         conn,
         {:error, %OAuth2.Response{body: %{"code" => code, "message" => message}}}
       ) do
    set_errors!(conn, [error("error_code_#{code}", "#{message} (#{code})")])
  end

  defp handle_failure(conn, {:error, %OAuth2.Response{status_code: status_code}}) do
    set_errors!(conn, [error("http_status_#{status_code}", "")])
  end

  defp handle_failure(
         conn,
         {:ok,
          %OAuth2.Client{
            token: %OAuth2.AccessToken{
              other_params: %{
                "error" => error_type,
                "error_description" => error_description
              }
            }
          }}
       ) do
    set_errors!(conn, [
      error(error_type, error_description)
    ])
  end

  # Private helpers

  defp option(conn, key) do
    Keyword.get(options(conn), key, Keyword.get(default_options(), key))
  end

  defp with_scope(opts, conn) do
    scope = conn.params["scope"] || option(conn, :default_scope)
    Keyword.put(opts, :scope, scope)
  end
end
