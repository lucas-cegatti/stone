defmodule StoneWeb.AuthErrorHandler do
  @moduledoc """
  Base authentication error handler.
  """
  import Plug.Conn

  @doc """
  Returns a json message with the authentication error and adds 401 as the response status
  """
  def auth_error(conn, {type, _reason}, _opts) do
    body = Jason.encode!(%{error: to_string(type)})

    conn
    |> put_resp_content_type("application/json")
    |> send_resp(401, body)
  end
end
