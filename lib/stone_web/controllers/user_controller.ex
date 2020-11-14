defmodule StoneWeb.UserController do
  use StoneWeb, :controller

  alias Stone.Accounts
  alias Stone.Accounts.User

  action_fallback StoneWeb.FallbackController

  def index(conn, _params) do
    users = Accounts.list_users()
    render(conn, "index.json", users: users)
  end

  def create(conn, %{"user" => user_params}) do
    with {:ok, %User{} = user} <- Accounts.create_user_with_checking_account(user_params) do
      conn
      |> put_status(:created)
      |> render("show.json", user: user)
    end
  end

  def show(conn, _params) do
    user = Guardian.Plug.current_resource(conn)
    render(conn, "show.json", user: user)
  end

  def sign_in(conn, %{"email" => email, "password" => password}) do
    case Accounts.user_sign_in(email, password) do
      {:ok, token, _claims} ->
        render(conn, "jwt.json", %{jwt: token})

      _ ->
        {:error, :unauthorized}
    end
  end
end
