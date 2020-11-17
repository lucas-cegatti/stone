defmodule Stone.Transactions.LedgerEvent do
  @moduledoc """
  Schema representing a ledger event at the database.

  Ledger event (or transaction) is stored at the database as a second source of truth, the main data is retrieved
  at the `Stone.Transactions.Ledgers` GenServer.
  """
  use Ecto.Schema
  import Ecto.Changeset

  alias Stone.Accounts.CheckingAccount

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "ledger_events" do
    field :number, :integer, read_after_writes: true
    field :amount, :integer
    field :description, :string
    field :type, Ecto.Enum, values: [:debit, :credit]
    field :event_date, :utc_datetime

    belongs_to :checking_account, CheckingAccount

    timestamps()
  end

  @doc false
  def changeset(ledger, attrs) do
    ledger
    |> cast(attrs, [:amount, :type, :description, :event_date, :checking_account_id])
    |> validate_required([:amount, :type, :description, :event_date, :checking_account_id])
  end
end
