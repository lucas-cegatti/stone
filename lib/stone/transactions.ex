defmodule Stone.Transactions do
  @moduledoc """
  The Transactions context.
  """

  import Ecto.Query, warn: false

  alias Stone.Transactions.{TransactionId, TransactionError, Ledgers}
  alias Stone.Accounts.CheckingAccount

  @doc """
  Returns a UUID stored at the gen server to be used for a user transaction

  ## Examples

      iex> get_transaction_id_for_checking_account()
      String.t()
  """
  def get_transaction_id_for_checking_account() do
    TransactionId.create()
  end

  @doc """
  Makes a withdrawal operation at the given account using the given amount.

  `amount` must be a positive integer
  `checking_account` Stone.Accounts.CheckingAccount
  """
  def withdrawal(amount, checking_account)

  def withdrawal(amount, _checking_account) when not is_integer(amount),
    do: TransactionError.invalid_transaction_amount(amount)

  def withdrawal(amount, _checking_account) when amount < 0,
    do: TransactionError.invalid_transaction_amount_negative_integer(amount)

  def withdrawal(_amount, nil),
    do: TransactionError.invalid_transaction_account_number("not found")

  @spec withdrawal(integer, Stone.Accounts.CheckingAccount.t()) :: {:ok} | TransactionError.t()
  def withdrawal(amount, %CheckingAccount{} = checking_account) do
    Ledgers.withdrawal(amount, checking_account)
  end
end
