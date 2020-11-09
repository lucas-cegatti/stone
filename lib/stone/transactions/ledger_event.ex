defmodule Stone.Transactions.LedgerEvent do
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
    |> cast(attrs, [:amount, :type, :description, :event_date])
    |> validate_required([:amount, :type, :description, :event_date])
  end
end
