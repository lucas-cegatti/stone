defmodule StoneWeb.UserView do
  use StoneWeb, :view
  alias StoneWeb.UserView

  def render("index.json", %{users: users}) do
    %{data: render_many(users, UserView, "user.json")}
  end

  def render("show.json", %{user: user}) do
    %{
      data: %{
        user: render_one(user, UserView, "user.json"),
        checking_account: render_one(user.checking_account, UserView, "account.json")
      }
    }
  end

  def render("user.json", %{user: user}) do
    %{id: user.id, name: user.name, email: user.email}
  end

  def render("account.json", %{user: checking_account}) do
    %{balance: checking_account.balance, number: checking_account.number}
  end

  def render("jwt.json", %{jwt: jwt}) do
    %{token: jwt}
  end
end
