defmodule Stone.TransactionsTest do
  use Stone.DataCase
  use ExUnitProperties

  alias Stone.Accounts
  alias Stone.Transactions
  alias Stone.Accounts.CheckingAccount
  alias Stone.Transactions.TransactionError

  describe "transactions withdrawal" do
    setup :setup_checking_account

    test "withdrawal/2 with valid data should return :ok, checking_account", %{
      checking_account: checking_account
    } do
      assert {:ok, %CheckingAccount{} = checking_account} =
               Transactions.withdrawal(1000, checking_account)
    end

    test "withdrawal/2 with valid data should update the checking account balance", %{
      checking_account: checking_account
    } do
      assert {:ok, %CheckingAccount{} = checking_account} =
               Transactions.withdrawal(1000, checking_account)

      assert checking_account.balance == 100_000 - 1000
    end

    test "withdrawal/2 with valid data should add one aditional event to the checking account ledger",
         %{
           checking_account: checking_account
         } do
      assert {:ok, %CheckingAccount{} = checking_account} =
               Transactions.withdrawal(1000, checking_account)

      checking_account = Accounts.get_checking_acount_by_id(checking_account.id)

      assert 2 == length(checking_account.ledger_events)
    end

    test "withdrawal/2 with valid data should add one debit event to the checking account ledger",
         %{
           checking_account: checking_account
         } do
      assert {:ok, %CheckingAccount{} = checking_account} =
               Transactions.withdrawal(1000, checking_account)

      checking_account = Accounts.get_checking_acount_by_id(checking_account.id)

      ledger_event = List.first(checking_account.ledger_events)

      assert ledger_event.type == :debit
      assert ledger_event.amount == 1000
    end

    test "withdrawal/2 should not accept negative values as amount",
         %{
           checking_account: checking_account
         } do
      assert %TransactionError{code: "T0005", message: message} =
               Transactions.withdrawal(-1000, checking_account)

      assert String.contains?(message, "-100")
    end

    test "withdrawal/2 should not accept non integer as values",
         %{
           checking_account: checking_account
         } do
      assert %TransactionError{code: "T0002", message: message} =
               Transactions.withdrawal("a", checking_account)

      assert %TransactionError{code: "T0002", message: message} =
               Transactions.withdrawal("-1000", checking_account)

      assert %TransactionError{code: "T0002", message: message} =
               Transactions.withdrawal(1.85, checking_account)
    end

    test "withdrawal/2 should not make transaction leading to negative balance", %{
      checking_account: checking_account
    } do
      assert %TransactionError{code: "T0003", message: message} =
               Transactions.withdrawal(101_000, checking_account)
    end

    test "withdrawal/2 should not accept invalid checking account" do
      assert %TransactionError{code: "T0004", message: message} =
               Transactions.withdrawal(1000, nil)
    end

    test "withdrawal/2 should successfully process a sequence of transactions", %{
      checking_account: checking_account
    } do
      check all amount <- StreamData.integer(100..1_000), max_runs: 30 do
        assert assert {:ok, %CheckingAccount{} = checking_account} =
                        Transactions.withdrawal(amount, checking_account)
      end

      checking_account = Accounts.get_checking_acount_by_id(checking_account.id)
      assert 31 == length(checking_account.ledger_events)
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
