defmodule Stone.Transactions.Transaction do
  use Ecto.Schema
  import Ecto.Changeset

  alias Stone.Accounts.CheckingAccount

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "transactions" do
    field :amount, :float
    field :destination, :string
    field :type, :string

    belongs_to :checking_account, CheckingAccount

    timestamps()
  end

  @doc false
  def changeset(transaction, attrs) do
    transaction
    |> cast(attrs, [:amount, :type, :destination])
    |> validate_required([:amount, :type, :destination])
  end
end
