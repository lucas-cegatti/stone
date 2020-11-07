defmodule Stone.Transactions.TransactionId do
  use GenServer

  @name TransactionIdGenServer

  def start_link(default \\ %{}) do
    GenServer.start_link(__MODULE__, default, name: @name)
  end

  @spec create :: String.t()
  def create() do
    GenServer.call(@name, {:create, []})
  end

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
