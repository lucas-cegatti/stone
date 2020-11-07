defmodule Stone.Transactions do
  @moduledoc """
  The Transactions context.
  """

  import Ecto.Query, warn: false
  alias Stone.Repo

  alias Stone.Transactions.{Transaction, TransactionId, TransactionError}
  alias Stone.Accounts.CheckingAccount

  @zero Decimal.new(0)

  @doc """
  Returns the list of transactions.

  ## Examples

      iex> list_transactions()
      [%Transaction{}, ...]

  """
  def list_transactions do
    Repo.all(Transaction)
  end

  @doc """
  Gets a single transaction.

  Raises `Ecto.NoResultsError` if the Transaction does not exist.

  ## Examples

      iex> get_transaction!(123)
      %Transaction{}

      iex> get_transaction!(456)
      ** (Ecto.NoResultsError)

  """
  def get_transaction!(id), do: Repo.get!(Transaction, id)

  @doc """
  Creates a transaction.

  ## Examples

      iex> create_transaction(%{field: value})
      {:ok, %Transaction{}}

      iex> create_transaction(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_transaction(attrs \\ %{}) do
    %Transaction{}
    |> Transaction.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a transaction.

  ## Examples

      iex> update_transaction(transaction, %{field: new_value})
      {:ok, %Transaction{}}

      iex> update_transaction(transaction, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_transaction(%Transaction{} = transaction, attrs) do
    transaction
    |> Transaction.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a transaction.

  ## Examples

      iex> delete_transaction(transaction)
      {:ok, %Transaction{}}

      iex> delete_transaction(transaction)
      {:error, %Ecto.Changeset{}}

  """
  def delete_transaction(%Transaction{} = transaction) do
    Repo.delete(transaction)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking transaction changes.

  ## Examples

      iex> change_transaction(transaction)
      %Ecto.Changeset{data: %Transaction{}}

  """
  def change_transaction(%Transaction{} = transaction, attrs \\ %{}) do
    Transaction.changeset(transaction, attrs)
  end

  @doc """
  Returns a UUID stored at the gen server to be used for a user transaction

  ## Examples

      iex> get_transaction_id_for_checking_account()
      String.t()
  """
  def get_transaction_id_for_checking_account() do
    TransactionId.create()
  end

  # def make_transaction(type, transaction_id, checking_account)

  @doc """
  First call will validate the transaction_id checking if it is valid
  """
  def make_transaction(:withdrawal, transaction_id, amount, checking_account)
      when is_bitstring(transaction_id) do
    make_transaction(:withdrawal, TransactionId.take(transaction_id), amount, checking_account)
  end

  @doc """
  If transaction_id is valid `{:ok, _opts}`, it will validate if the amount value is valid
  """
  def make_transaction(:withdrawal, {:ok, _opts} = transaction_id, amount, checking_account)
      when is_bitstring(amount) do
    make_transaction(:withdrawal, transaction_id, Decimal.cast(amount), checking_account)
  end

  @doc """
  If both transaction id and amount are valid it will proceed to the final step of the transaction
  to validate the final balance and finally make the transaction.
  """
  def make_transaction(
        :withdrawal,
        {:ok, _opts},
        {:ok, decimal_amount},
        %CheckingAccount{} = checking_account
      ) do
    current_balance = Decimal.new(checking_account.balance)
    new_balance = Decimal.sub(current_balance, decimal_amount)

    case Decimal.lt?(new_balance, @zero) do
      true ->
        TransactionError.invalid_transaction_negative_balance_result(
          Decimal.to_string(decimal_amount),
          Decimal.to_string(current_balance)
        )

      false ->
        do_transaction(
          :withdrawal,
          checking_account,
          Decimal.to_float(decimal_amount),
          Decimal.to_float(new_balance),
          :self
        )
    end
  end

  def make_transaction(_, {:error, :not_found, transaction_id}, _, _checking_account),
    do: TransactionError.invalid_transaction_id_error(transaction_id)

  def make_transaction(_, _, :error, _checking_account),
    do: TransactionError.invalid_transaction_amount("")

  defp do_transaction(
         type,
         %CheckingAccount{} = checking_account,
         amount,
         new_balance,
         :self
       ) do
    base_transaction_multi(type, checking_account, amount, new_balance)
    |> Repo.transaction()
    |> case do
      {:ok, %{transaction: transaction}} ->
        {:ok, transaction}

      {:error, _failed_operation, failed_value, _changes_so_far} ->
        {:error, failed_value}
    end
  end

  defp base_transaction_multi(type, %CheckingAccount{} = checking_account, amount, new_balance) do
    attrs = %{
      type: type,
      checking_account_id: checking_account.id,
      amount: amount
    }

    Ecto.Multi.new()
    |> Ecto.Multi.insert(:transaction, Transaction.changeset(%Transaction{}, attrs))
    |> Ecto.Multi.update(
      :checking_account,
      CheckingAccount.update_changeset(checking_account, %{balance: new_balance})
    )
  end
end
