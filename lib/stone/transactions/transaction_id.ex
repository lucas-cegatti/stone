defmodule Stone.Transactions.TransactionId do
  @moduledoc """
  An Agent implementation to store and retrieve Transactions IDs.

  Transaction IDs are used to avoid duplicated transactions to be processed, it's only a basic and simple solution to avoid the problem.
  """
  use Agent

  def start_link(initial_value \\ %{}) do
    Agent.start_link(fn -> initial_value end, name: __MODULE__)
  end

  @doc """
  Creates a new transaction id, stores it at the Agent state and returns the new id.

  Transaction ids are UUID generated via `Ecto.UUID.generate/0`

  Returns `String.t()`

  ## Examples
      iex> Stone.Transactions.TransactionId.create()
      "18a0a7ed-00c0-4c8b-86e9-cafe8588e823"
  """
  @spec create :: String.t()
  def create do
    transaction_id = create_transaction_id()

    Agent.update(__MODULE__, &Map.put(&1, transaction_id, []))

    transaction_id
  end

  @doc """
  Takes the transaction id, this is used to validate if the transaction id is valid, i.e. it's present at the Agent state.

  Returns {:ok, opts} | {:error, :not_found, String.t()}

   ## Examples
      iex> Stone.Transactions.TransactionId.take("18a0a7ed-00c0-4c8b-86e9-cafe8588e823")
      {:ok, []}

      iex> Stone.Transactions.TransactionId.take("invalid")
      {:error, :not_found, "invalid"}
  """
  @spec take(String.t()) :: {:ok, List.t()} | {:error, :not_found, String.t()}
  def take(transaction_id) do
    case Agent.get_and_update(__MODULE__, &Map.pop(&1, transaction_id)) do
      nil ->
        {:error, :not_found, transaction_id}

      opts ->
        {:ok, opts}
    end
  end

  defp create_transaction_id do
    Ecto.UUID.generate()
  end
end
