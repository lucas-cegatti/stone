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
      transaction_id = Transactions.get_transaction_id_for_checking_account()

      assert {:ok, %CheckingAccount{} = checking_account} =
               Transactions.withdrawal(1000, checking_account, transaction_id)
    end

    test "withdrawal/2 with valid data should update the checking account balance", %{
      checking_account: checking_account
    } do
      transaction_id = Transactions.get_transaction_id_for_checking_account()

      assert {:ok, %CheckingAccount{} = checking_account} =
               Transactions.withdrawal(1000, checking_account, transaction_id)

      assert checking_account.balance == 100_000 - 1000
    end

    test "withdrawal/2 with valid data should add one aditional event to the checking account ledger",
         %{
           checking_account: checking_account
         } do
      transaction_id = Transactions.get_transaction_id_for_checking_account()

      assert {:ok, %CheckingAccount{} = checking_account} =
               Transactions.withdrawal(1000, checking_account, transaction_id)

      checking_account = Accounts.get_checking_acount_by_id(checking_account.id)

      assert 2 == length(checking_account.ledger_events)
    end

    test "withdrawal/2 with valid data should add one debit event to the checking account ledger",
         %{
           checking_account: checking_account
         } do
      transaction_id = Transactions.get_transaction_id_for_checking_account()

      assert {:ok, %CheckingAccount{} = checking_account} =
               Transactions.withdrawal(1000, checking_account, transaction_id)

      checking_account = Accounts.get_checking_acount_by_id(checking_account.id)

      ledger_event = List.first(checking_account.ledger_events)

      assert ledger_event.type == :debit
      assert ledger_event.amount == 1000
    end

    test "withdrawal/2 should not accept negative values as amount",
         %{
           checking_account: checking_account
         } do
      transaction_id = Transactions.get_transaction_id_for_checking_account()

      assert %TransactionError{code: "T0005", message: message} =
               Transactions.withdrawal(-1000, checking_account, transaction_id)

      assert String.contains?(message, "-100")
    end

    test "withdrawal/2 should not accept non integer as values",
         %{
           checking_account: checking_account
         } do
      transaction_id = Transactions.get_transaction_id_for_checking_account()

      assert %TransactionError{code: "T0002", message: message} =
               Transactions.withdrawal("a", checking_account, transaction_id)

      assert %TransactionError{code: "T0002", message: message} =
               Transactions.withdrawal("-1000", checking_account, transaction_id)

      assert %TransactionError{code: "T0002", message: message} =
               Transactions.withdrawal(1.85, checking_account, transaction_id)
    end

    test "withdrawal/2 should not make transaction leading to negative balance", %{
      checking_account: checking_account
    } do
      transaction_id = Transactions.get_transaction_id_for_checking_account()

      assert %TransactionError{code: "T0003", message: message} =
               Transactions.withdrawal(101_000, checking_account, transaction_id)
    end

    test "withdrawal/2 should not accept invalid checking account" do
      transaction_id = Transactions.get_transaction_id_for_checking_account()

      assert %TransactionError{code: "T0004", message: message} =
               Transactions.withdrawal(1000, nil, transaction_id)
    end

    test "withdrawal/2 should successfully process a sequence of transactions", %{
      checking_account: checking_account
    } do
      check all(
              amount <- StreamData.integer(100..1_000),
              transaction_id <-
                StreamData.constant(Transactions.get_transaction_id_for_checking_account()),
              max_runs: 30
            ) do
        assert assert {:ok, %CheckingAccount{} = checking_account} =
                        Transactions.withdrawal(amount, checking_account, transaction_id)
      end

      checking_account = Accounts.get_checking_acount_by_id(checking_account.id)
      assert 31 == length(checking_account.ledger_events)

      assert checking_account.balance < 100_000
    end

    test "withdrawal/2 with invalid transaction id should return an error", %{
      checking_account: checking_account
    } do
      transaction_id = Ecto.UUID.generate()

      assert %TransactionError{code: "T0001", message: message} =
               Transactions.withdrawal(101_000, checking_account, transaction_id)

      assert String.contains?(message, transaction_id)
    end
  end

  describe "transactions transfer" do
    setup [:setup_checking_account, :setup_second_checking_account]

    test "transfer/4 with valid data should return :ok, checking account", %{
      checking_account: checking_account,
      second_checking_account: second_checking_account
    } do
      transaction_id = Transactions.get_transaction_id_for_checking_account()

      assert {:ok, %CheckingAccount{} = checking_account} =
               Transactions.transfer(
                 100,
                 checking_account,
                 second_checking_account,
                 transaction_id
               )
    end

    test "transfer/4 with valid data should return the debit checking account at the response", %{
      checking_account: checking_account,
      second_checking_account: second_checking_account
    } do
      transaction_id = Transactions.get_transaction_id_for_checking_account()

      assert {:ok, %CheckingAccount{} = response_checking_account} =
               Transactions.transfer(
                 100,
                 checking_account,
                 second_checking_account,
                 transaction_id
               )

      assert response_checking_account.id == checking_account.id
    end

    test "transfer/4 with valid data should debit the source account", %{
      checking_account: checking_account,
      second_checking_account: second_checking_account
    } do
      transaction_id = Transactions.get_transaction_id_for_checking_account()
      old_balance = checking_account.balance

      assert {:ok, %CheckingAccount{} = response_checking_account} =
               Transactions.transfer(
                 100,
                 checking_account,
                 second_checking_account,
                 transaction_id
               )

      assert response_checking_account.balance == old_balance - 100
    end

    test "transfer/4 with valid data should credit the destination account", %{
      checking_account: checking_account,
      second_checking_account: second_checking_account
    } do
      transaction_id = Transactions.get_transaction_id_for_checking_account()
      old_balance = second_checking_account.balance

      assert {:ok, %CheckingAccount{} = response_checking_account} =
               Transactions.transfer(
                 100,
                 checking_account,
                 second_checking_account,
                 transaction_id
               )

      second_checking_account = Accounts.get_checking_acount_by_id(second_checking_account.id)
      assert second_checking_account.balance == old_balance + 100
    end

    test "transfer/4 with valid data should add one debit ledger to the source account", %{
      checking_account: checking_account,
      second_checking_account: second_checking_account
    } do
      transaction_id = Transactions.get_transaction_id_for_checking_account()

      assert {:ok, %CheckingAccount{} = response_checking_account} =
               Transactions.transfer(
                 100,
                 checking_account,
                 second_checking_account,
                 transaction_id
               )

      response_checking_account = Accounts.get_checking_acount_by_id(response_checking_account.id)
      debit_ledger = List.first(response_checking_account.ledger_events)

      assert debit_ledger.type == :debit
      assert debit_ledger.amount == 100
    end

    test "transfer/4 with valid data should add one credit ledger to the destination account", %{
      checking_account: checking_account,
      second_checking_account: second_checking_account
    } do
      transaction_id = Transactions.get_transaction_id_for_checking_account()

      assert {:ok, %CheckingAccount{} = response_checking_account} =
               Transactions.transfer(
                 100,
                 checking_account,
                 second_checking_account,
                 transaction_id
               )

      second_checking_account = Accounts.get_checking_acount_by_id(second_checking_account.id)
      debit_ledger = List.first(second_checking_account.ledger_events)

      assert debit_ledger.type == :credit
      assert debit_ledger.amount == 100
    end

    test "transfer/4 with invalid transaction id should return Transaction Error", %{
      checking_account: checking_account,
      second_checking_account: second_checking_account
    } do
      transaction_id = Ecto.UUID.generate()

      assert %TransactionError{code: "T0001", message: message} =
               Transactions.transfer(
                 100,
                 checking_account,
                 second_checking_account,
                 transaction_id
               )

      assert String.contains?(message, transaction_id)
    end

    test "transfer/4 with negative amount should return Transaction Error", %{
      checking_account: checking_account,
      second_checking_account: second_checking_account
    } do
      transaction_id = Transactions.get_transaction_id_for_checking_account()

      assert %TransactionError{code: "T0005", message: message} =
               Transactions.transfer(
                 -100,
                 checking_account,
                 second_checking_account,
                 transaction_id
               )
    end

    test "transfer/4 with non integer amount should return Transaction Error", %{
      checking_account: checking_account,
      second_checking_account: second_checking_account
    } do
      transaction_id = Transactions.get_transaction_id_for_checking_account()

      assert %TransactionError{code: "T0002", message: message} =
               Transactions.transfer(
                 "a",
                 checking_account,
                 second_checking_account,
                 transaction_id
               )

      assert %TransactionError{code: "T0002", message: message} =
               Transactions.transfer(
                 1.5,
                 checking_account,
                 second_checking_account,
                 transaction_id
               )

      assert %TransactionError{code: "T0002", message: message} =
               Transactions.transfer(
                 "100",
                 checking_account,
                 second_checking_account,
                 transaction_id
               )
    end

    test "transfer/4 with invalid source checking account should return Transaction Error", %{
      checking_account: _checking_account,
      second_checking_account: second_checking_account
    } do
      transaction_id = Transactions.get_transaction_id_for_checking_account()

      assert %TransactionError{code: "T0004", message: message} =
               Transactions.transfer(
                 100,
                 nil,
                 second_checking_account,
                 transaction_id
               )
    end

    test "transfer/4 with invalid destination checking account should return Transaction Error",
         %{
           checking_account: checking_account,
           second_checking_account: _second_checking_account
         } do
      transaction_id = Transactions.get_transaction_id_for_checking_account()

      assert %TransactionError{code: "T0004", message: message} =
               Transactions.transfer(
                 100,
                 checking_account,
                 nil,
                 transaction_id
               )
    end

    test "transfer/4 with with amount higher than balance, leading to negative balance, should return Transaction Error",
         %{
           checking_account: checking_account,
           second_checking_account: second_checking_account
         } do
      transaction_id = Transactions.get_transaction_id_for_checking_account()

      assert %TransactionError{code: "T0003", message: message} =
               Transactions.transfer(
                 100_001,
                 checking_account,
                 second_checking_account,
                 transaction_id
               )
    end

    test "transfer/4 with with amount higher than balance, leading to negative balance, should not create ledger events",
         %{
           checking_account: checking_account,
           second_checking_account: second_checking_account
         } do
      transaction_id = Transactions.get_transaction_id_for_checking_account()

      assert %TransactionError{code: "T0003", message: message} =
               Transactions.transfer(
                 100_001,
                 checking_account,
                 second_checking_account,
                 transaction_id
               )

      checking_account = Accounts.get_checking_acount_by_id(checking_account.id)
      second_checking_account = Accounts.get_checking_acount_by_id(second_checking_account.id)

      assert 1 == length(checking_account.ledger_events)
      assert 1 == length(second_checking_account.ledger_events)
    end

    test "transfer/4 should successfully process a sequence of transactions", %{
      checking_account: checking_account,
      second_checking_account: second_checking_account
    } do
      check all(
              amount <- StreamData.integer(100..1_000),
              transaction_id <-
                StreamData.constant(Transactions.get_transaction_id_for_checking_account()),
              max_runs: 30
            ) do
        assert {:ok, %CheckingAccount{} = checking_account} =
                        Transactions.transfer(
                          amount,
                          checking_account,
                          second_checking_account,
                          transaction_id
                        )
      end

      checking_account = Accounts.get_checking_acount_by_id(checking_account.id)
      second_checking_account = Accounts.get_checking_acount_by_id(second_checking_account.id)

      assert 31 == length(checking_account.ledger_events)
      assert 31 == length(second_checking_account.ledger_events)

      transfered = second_checking_account.balance - 100_000

      assert 100_000 == transfered + checking_account.balance
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

  defp setup_second_checking_account(_context) do
    valid_user_attrs = %{
      email: "bar@foo.com",
      name: "Bar Foo",
      password: "passwordHash",
      password_confirmation: "passwordHash"
    }

    {:ok, user} = valid_user_attrs |> Accounts.create_user_with_checking_account()

    [second_checking_account: user.checking_account]
  end
end
