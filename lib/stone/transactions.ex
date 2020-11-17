defmodule Stone.Transactions do
  @moduledoc """
  The Transactions context.
  """

  import Ecto.Query, warn: false

  alias Stone.Accounts.CheckingAccount
  alias Stone.Transactions.{Ledgers, TransactionError, TransactionId}

  @doc """
  Returns a UUID stored at the gen server to be used for a user transaction.

  Every withdrawal or transfer transaction must receive a valid transaction id, this is used to avoid the same transaction to be processed twice.

  ## Examples

      iex> get_transaction_id_for_checking_account()
      String.t()
  """
  def get_transaction_id_for_checking_account do
    TransactionId.create()
  end

  @doc """
  Makes a withdrawal operation at the given account using the given amount.

  `amount` must be a positive integer
  `checking_account` Stone.Accounts.CheckingAccount
  """
  def withdrawal(amount, checking_account, _transaction_id, opts \\ [])

  def withdrawal(amount, _checking_account, _transaction_id, _opts) when not is_integer(amount),
    do: TransactionError.invalid_transaction_amount(amount)

  def withdrawal(amount, _checking_account, _transaction_id, _opts) when amount < 0,
    do: TransactionError.invalid_transaction_amount_negative_integer(amount)

  def withdrawal(_amount, nil, _transaction_id, _opts),
    do: TransactionError.invalid_transaction_account_number("not found")

  @spec withdrawal(integer, Stone.Accounts.CheckingAccount.t(), String.t()) ::
          {:ok, Stone.Transactions.LedgerEvent.t()}
          | TransactionError.t()
          | {:error, Ecto.Changeset.t()}
  def withdrawal(amount, %CheckingAccount{} = checking_account, transaction_id, opts) do
    case TransactionId.take(transaction_id) do
      {:ok, _opts} -> Ledgers.withdrawal(amount, checking_account, opts)
      _ -> TransactionError.invalid_transaction_id_error(transaction_id)
    end
  end

  @doc """
  Makes a transfer creating a debit on the checking account and transferring to the destination account by creating a credit a the account.

  Both are registered as ledger events

  `amount` must be a positive integer
  `checking_account` Stone.Accounts.CheckingAccount
  `destination_checking_account` Stone.Accounts.CheckingAccount
  """
  def transfer(
        amount,
        checking_account,
        destination_checking_account,
        _transaction_id,
        opts \\ []
      )

  def transfer(amount, _checking_account, _destination_checking_account, _transaction_id, _opts)
      when not is_integer(amount),
      do: TransactionError.invalid_transaction_amount(amount)

  def transfer(amount, _checking_account, _destination_checking_account, _transaction_id, _opts)
      when amount < 0,
      do: TransactionError.invalid_transaction_amount_negative_integer(amount)

  def transfer(_amount, nil, _destination_checking_account, _transaction_id, _opts),
    do: TransactionError.invalid_transaction_account_number("not found")

  def transfer(_amount, _checking_account, nil, _transaction_id, _opts),
    do: TransactionError.invalid_transaction_account_number("not found")

  def transfer(
        _amount,
        %CheckingAccount{id: from_id},
        %CheckingAccount{id: to_id},
        _transaction_id,
        _opts
      )
      when from_id == to_id,
      do: TransactionError.invalid_transaction_transfer_same_destination_account()

  @spec transfer(
          integer,
          Stone.Accounts.CheckingAccount.t(),
          Stone.Accounts.CheckingAccount.t(),
          String.t()
        ) ::
          {:ok, Stone.Transactions.LedgerEvent.t()}
          | TransactionError.t()
          | {:error, Ecto.Changeset.t()}
  def transfer(
        amount,
        %CheckingAccount{} = checking_account,
        %CheckingAccount{} = destination_checking_account,
        transaction_id,
        opts
      ) do
    case TransactionId.take(transaction_id) do
      {:ok, _opts} ->
        Ledgers.transfer(amount, checking_account, destination_checking_account, opts)

      _ ->
        TransactionError.invalid_transaction_id_error(transaction_id)
    end
  end
end
