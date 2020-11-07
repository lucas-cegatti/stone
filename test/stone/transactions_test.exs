defmodule Stone.TransactionsTest do
  use Stone.DataCase

  alias Stone.Accounts
  alias Stone.Transactions

  describe "transactions withdrawal" do
    alias Stone.Transactions.{Transaction, TransactionId, TransactionError}

    setup :setup_checking_account

    test "make_transaction/4 with valid data creates a transaction", %{
      checking_account: checking_account
    } do
      assert {:ok, %Transaction{} = transaction} =
               Transactions.make_transaction(
                 :withdrawal,
                 TransactionId.create(),
                 "100",
                 checking_account
               )

      assert transaction.type == :withdrawal
      assert transaction.amount == 100
    end

    test "make_transaction/4 with valid data substracts the amount from the checking account", %{
      checking_account: checking_account
    } do
      amount = "100"
      {:ok, decimal_amount} = Decimal.cast(amount)
      decimal_balance = Decimal.from_float(checking_account.balance)
      new_balance = Decimal.sub(decimal_balance, decimal_amount)

      assert {:ok, %Transaction{} = transaction} =
               Transactions.make_transaction(
                 :withdrawal,
                 TransactionId.create(),
                 amount,
                 checking_account
               )

      checking_account = Accounts.get_checking_acount_by_id(checking_account.id)
      checking_account_decimal_balance = Decimal.from_float(checking_account.balance)

      assert Decimal.eq?(checking_account_decimal_balance, new_balance)
    end
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
