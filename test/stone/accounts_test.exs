defmodule Stone.AccountsTest do
  use Stone.DataCase

  alias Stone.Accounts

  describe "users" do
    alias Stone.Accounts.User

    @valid_attrs %{
      email: "foo@bar.com",
      name: "Foo Bar",
      password: "passwordHash",
      password_confirmation: "passwordHash"
    }
    @update_attrs %{
      email: "foo1@bar.com",
      name: "Foo Bar 1",
      password: "passwordHash",
      password_confirmation: "passwordHash"
    }
    @invalid_attrs %{email: nil, name: nil, password: nil}

    def user_fixture(attrs \\ %{}) do
      {:ok, user} =
        attrs
        |> Enum.into(@valid_attrs)
        |> Accounts.create_user()

      %{user | password: nil, password_confirmation: nil}
    end

    test "list_users/0 returns all users" do
      user = user_fixture()
      assert Accounts.list_users() == [user]
    end

    test "get_user!/1 returns the user with given id" do
      user = user_fixture()
      assert Accounts.get_user!(user.id) == user
    end

    test "create_user/1 with valid data creates a user" do
      assert {:ok, %User{} = user} = Accounts.create_user(@valid_attrs)
      assert user.email == @valid_attrs.email
      assert user.name == @valid_attrs.name
      assert Bcrypt.check_pass(user, @valid_attrs.password)
    end

    test "create_user/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Accounts.create_user(@invalid_attrs)
    end

    test "update_user/2 with valid data updates the user" do
      user = user_fixture()
      assert {:ok, %User{} = user} = Accounts.update_user(user, @update_attrs)
      assert user.email == @update_attrs.email
      assert user.name == @update_attrs.name
      assert Bcrypt.check_pass(user, @update_attrs.password)
    end

    test "update_user/2 with invalid data returns error changeset" do
      user = user_fixture()
      assert {:error, %Ecto.Changeset{}} = Accounts.update_user(user, @invalid_attrs)
      assert user == Accounts.get_user!(user.id)
    end

    test "delete_user/1 deletes the user" do
      user = user_fixture()
      assert {:ok, %User{}} = Accounts.delete_user(user)
      assert_raise Ecto.NoResultsError, fn -> Accounts.get_user!(user.id) end
    end

    test "change_user/1 returns a user changeset" do
      user = user_fixture()
      assert %Ecto.Changeset{} = Accounts.change_user(user)
    end

    test "user_sign_in/2 with valid data returns a jwt token" do
      user_fixture()

      assert {:ok, token, _claim} =
               Accounts.user_sign_in(@valid_attrs.email, @valid_attrs.password)

      assert String.match?(token, ~r/[A-Za-z0-9\-\._~\+\/]+=*/)
    end

    test "user_sign_in/2 with invalid password returns {:error, :unauthorized}" do
      user_fixture()

      assert {:error, :unauthorized} = Accounts.user_sign_in(@valid_attrs.email, "invalid_pass")
    end

    test "user_sign_in/2 with invalid email returns {:error, :unauthorized}" do
      user_fixture()

      assert {:error, :unauthorized} = Accounts.user_sign_in("bar@foo.com", @valid_attrs.password)
    end

    test "create_user_with_checking_account/1 with valid data creates user" do
      assert {:ok, %User{} = user} = Accounts.create_user_with_checking_account(@valid_attrs)
      assert user.email == @valid_attrs.email
      assert user.name == @valid_attrs.name
      assert Bcrypt.check_pass(user, @valid_attrs.password)
    end

    test "create_user_with_checking_account/1 with valid data creates user with account" do
      assert {:ok, %User{} = user} = Accounts.create_user_with_checking_account(@valid_attrs)

      assert user.checking_account
      assert user.checking_account.number
    end

    test "create_user_with_checking_account/1 with valid data creates user account with 1_000 in balance " do
      assert {:ok, %User{} = user} = Accounts.create_user_with_checking_account(@valid_attrs)

      assert user.checking_account.balance == 100_000
    end

    test "create_user_with_checking_account/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} =
               Accounts.create_user_with_checking_account(@invalid_attrs)
    end

    test "create_user_with_checking_account/1 with valid data add 1 ledger event of credit" do
      assert {:ok, %User{} = user} = Accounts.create_user_with_checking_account(@valid_attrs)

      assert user.checking_account.balance == 100_000
      assert [ledger_event | []] = user.checking_account.ledger_events

      assert ledger_event.type == :credit
      assert ledger_event.amount == 100_000
      # assert ledger_event.number == 1
    end
  end
end
