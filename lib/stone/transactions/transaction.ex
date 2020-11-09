defmodule Stone.Transactions.Transaction do
  use Ecto.Schema
  import Ecto.Changeset

  alias Stone.Accounts.CheckingAccount

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "transactions" do
    field :amount, :integer
    field :destination, :string
    field :type, Ecto.Enum, values: [:withdrawal, :transfer]

    belongs_to :checking_account, CheckingAccount

    timestamps()
  end

  @required_create_fields ~w(amount type checking_account_id)a
  @optional_create_fields ~w(destination)a

  @doc false
  def changeset(transaction, attrs) do
    transaction
    |> cast(attrs, @required_create_fields ++ @optional_create_fields)
    |> validate_required(@required_create_fields)
  end
end
