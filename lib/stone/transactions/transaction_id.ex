defmodule Stone.Transactions.TransactionId do
  @moduledoc """
  A GenServer implementation to store and retrieve Transactions IDs.

  Transaction IDs are used to avoid duplicated transactions to be processed, it's only a basic and simple solution to avoid the problem.
  """
  use GenServer

  @name TransactionIdGenServer

  def start_link(default \\ %{}) do
    GenServer.start_link(__MODULE__, default, name: @name)
  end

  @doc """
  Creates a new transaction id, stores it at the GenServer state and returns the new id.

  Transaction ids are UUID generated via `Ecto.UUID.generate/0`

  Returns `String.t()`

  ## Examples
      iex> Stone.Transactions.TransactionId.create()
      "18a0a7ed-00c0-4c8b-86e9-cafe8588e823"
  """
  @spec create :: String.t()
  def create() do
    GenServer.call(@name, {:create, []})
  end

  @doc """
  Takes the transaction id, this is used to validate if the transaction id is valid, i.e. it's present at the GenServer state.

  Returns {:ok, opts} | {:error, :not_found, String.t()}

   ## Examples
      iex> Stone.Transactions.TransactionId.take("18a0a7ed-00c0-4c8b-86e9-cafe8588e823")
      {:ok, []}

      iex> Stone.Transactions.TransactionId.take("invalid")
      {:error, :not_found, "invalid"}
  """
  @spec take(String.t()) :: {:ok, List.t()} | {:error, :not_found, String.t()}
  def take(transaction_id) do
    GenServer.call(@name, {:take, transaction_id})
  end

  @impl true
  def init(transaction_ids) do
    {:ok, transaction_ids}
  end

  @impl true
  def handle_call({:create, opts}, _from, transaction_ids) do
    transaction_id = create_transaction_id()

    {:reply, transaction_id, Map.put(transaction_ids, transaction_id, opts)}
  end

  @impl true
  def handle_call({:take, transaction_id}, _from, transaction_ids) do
    {data, map} =
      case Map.pop(transaction_ids, transaction_id) do
        {nil, map} -> {{:error, :not_found, transaction_id}, map}
        {opts, map} -> {{:ok, opts}, map}
      end

    {:reply, data, map}
  end

  defp create_transaction_id do
    Ecto.UUID.generate()
  end
end
