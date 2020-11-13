defmodule StoneWeb.UserControllerTest do
  use StoneWeb.ConnCase

  alias Stone.Accounts
  alias Stone.Accounts.User

  @create_attrs %{
    email: "foo@bar.com",
    name: "Foo Bar",
    password: "passwordHash",
    password_confirmation: "passwordHash"
  }
  @update_attrs %{
    email: "foo1@bar.com",
    name: "Foo Bar 1",
    password: "passwordHash1",
    password_confirmation: "passwordHash1"
  }
  @invalid_attrs %{email: nil, name: nil, password: nil}

  def fixture(:user) do
    {:ok, user} = Accounts.create_user(@create_attrs)
    user
  end

  setup %{conn: conn} do
    {:ok, conn: put_req_header(conn, "accept", "application/json")}
  end

  describe "index" do
    @tag :skip
    test "lists all users", %{conn: conn} do
      conn = get(conn, Routes.user_path(conn, :index))
      assert json_response(conn, 200)["data"] == []
    end
  end

  describe "create user" do
    test "renders user when data is valid", %{conn: conn} do
      conn = post(conn, Routes.user_path(conn, :create), user: @create_attrs)
      assert %{"id" => _id, "name" => name, "email" => email} = json_response(conn, 201)["data"]

      assert name == @create_attrs.name
      assert email == @create_attrs.email
    end

    test "renders errors when data is invalid", %{conn: conn} do
      conn = post(conn, Routes.user_path(conn, :create), user: @invalid_attrs)
      assert json_response(conn, 422)["errors"] != %{}
    end
  end

  describe "update user" do
    setup [:create_user]

    @tag :skip
    test "renders user when data is valid", %{conn: conn, user: %User{id: id} = user} do
      conn = put(conn, Routes.user_path(conn, :update, user), user: @update_attrs)
      assert %{"id" => ^id} = json_response(conn, 200)["data"]

      conn = get(conn, Routes.user_path(conn, :show, id))

      assert %{
               "id" => _id,
               "email" => "foo1@bar.com",
               "name" => "Foo Bar 1"
             } = json_response(conn, 200)["data"]
    end

    @tag :skip
    test "renders errors when data is invalid", %{conn: conn, user: user} do
      conn = put(conn, Routes.user_path(conn, :update, user), user: @invalid_attrs)
      assert json_response(conn, 422)["errors"] != %{}
    end
  end

  describe "delete user" do
    setup [:create_user]

    @tag :skip
    test "deletes chosen user", %{conn: conn, user: user} do
      conn = delete(conn, Routes.user_path(conn, :delete, user))
      assert response(conn, 204)

      assert_error_sent 404, fn ->
        get(conn, Routes.user_path(conn, :show, user))
      end
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

      assert %{"error" => "Falha de Autenticação"} = json_response(conn, 401)
    end

    test "signing in user with invalid email returns 401 unauthorized", %{
      conn: conn,
      user: %User{email: _email, password: password}
    } do
      conn =
        post(conn, Routes.user_path(conn, :sign_in), email: "bar@foo.com", password: password)

      assert %{"error" => "Falha de Autenticação"} = json_response(conn, 401)
    end
  end

  defp create_user(_) do
    user = fixture(:user)
    %{user: user}
  end
end
