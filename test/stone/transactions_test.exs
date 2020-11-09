defmodule Stone.TransactionsTest do
  use Stone.DataCase

  alias Stone.Accounts
  alias Stone.Transactions

  describe "transactions withdrawal" do

  end

  defp setup_checking_account(_context) do
    valid_user_attrs = %{
      email: "foo@bar.com",
      name: "Foo Bar",
      password: "passwordHash",
      password_confirmation: "passwordHash"
    }

    {:ok, user} = valid_user_attrs |> Accounts.create_user_with_checking_account()

    [checking_account: user.checking_account]
  end
end
