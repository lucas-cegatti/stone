defmodule StoneWeb.UserControllerTest do
  use StoneWeb.ConnCase

  import Stone.Guardian

  alias Stone.Accounts
  alias Stone.Accounts.User

  @create_attrs %{
    email: "foo@bar.com",
    name: "Foo Bar",
    password: "passwordHash",
    password_confirmation: "passwordHash"
  }

  @invalid_attrs %{email: nil, name: nil, password: nil}

  def fixture(:user) do
    {:ok, user} = Accounts.create_user_with_checking_account(@create_attrs)
    user
  end

  setup %{conn: conn} do
    {:ok, conn: put_req_header(conn, "accept", "application/json")}
  end

  describe "sign up" do
    test "renders user when data is valid", %{conn: conn} do
      conn = post(conn, Routes.user_path(conn, :create), user: @create_attrs)

      assert %{"user" => %{"id" => _id, "name" => name, "email" => email}} =
               json_response(conn, 201)["data"]

      assert name == @create_attrs.name
      assert email == @create_attrs.email
    end

    test "renders errors when data is invalid", %{conn: conn} do
      conn = post(conn, Routes.user_path(conn, :create), user: @invalid_attrs)
      assert json_response(conn, 422)["errors"] != %{}
    end

    test "renders errors when repeated email is given", %{conn: conn} do
      conn = post(conn, Routes.user_path(conn, :create), user: @create_attrs)

      assert %{"user" => %{"id" => _id, "name" => _name, "email" => _email}} =
        json_response(conn, 201)["data"]

      conn = post(conn, Routes.user_path(conn, :create), user: @create_attrs)
      assert json_response(conn, 422)["errors"] != %{}
    end
  end

  describe "sign_in" do
    setup [:create_user]

    test "signing in user with valid data returns a valid token", %{
      conn: conn,
      user: %User{email: email, password: password}
    } do
      conn = post(conn, Routes.user_path(conn, :sign_in), email: email, password: password)

      assert %{"token" => token} = json_response(conn, 200)
      assert String.match?(token, ~r/[A-Za-z0-9\-\._~\+\/]+=*/)
    end

    test "signing in user with invalid password returns 401 unauthorized", %{
      conn: conn,
      user: %User{email: email, password: _password}
    } do
      conn = post(conn, Routes.user_path(conn, :sign_in), email: email, password: "invalid_pass")

      assert %{"error" => "Authentication Failed"} = json_response(conn, 401)
    end

    test "signing in user with invalid email returns 401 unauthorized", %{
      conn: conn,
      user: %User{email: _email, password: password}
    } do
      conn =
        post(conn, Routes.user_path(conn, :sign_in), email: "bar@foo.com", password: password)

      assert %{"error" => "Authentication Failed"} = json_response(conn, 401)
    end
  end

  describe "self" do
    setup [:create_user]

    test "GET /self with valid token returns user and checking account data", %{
      conn: conn,
      user: user
    } do
      {:ok, token, _} = encode_and_sign(user, %{}, token_type: :access)

      conn =
        conn
        |> put_req_header("accept", "application/json")
        |> put_req_header("authorization", "Bearer " <> token)
        |> get(Routes.user_path(conn, :show))

      assert %{"user" => _user, "checking_account" => _checking_account} =
               json_response(conn, 200)["data"]
    end

    test "GET /self with valid token returns user and checking account valid data", %{
      conn: conn,
      user: user
    } do
      {:ok, token, _} = encode_and_sign(user, %{}, token_type: :access)

      conn =
        conn
        |> put_req_header("accept", "application/json")
        |> put_req_header("authorization", "Bearer " <> token)
        |> get(Routes.user_path(conn, :show))

      assert %{"user" => r_user, "checking_account" => r_checking_account} =
               json_response(conn, 200)["data"]

      assert user.id == r_user["id"]
      assert user.checking_account.number == r_checking_account["number"]
    end

    test "GET /self with invalid token returns 401 unauthorized", %{
      conn: conn
    } do
      conn =
        conn
        |> put_req_header("accept", "application/json")
        |> put_req_header("authorization", "Bearer " <> "invalid")
        |> get(Routes.user_path(conn, :show))

      assert %{"error" => "invalid_token"} = json_response(conn, 401)
    end
  end

  defp create_user(_) do
    user = fixture(:user)
    %{user: user}
  end
end
