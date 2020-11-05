defmodule Stone.Accounts.CheckingAccount do
  use Ecto.Schema
  import Ecto.Changeset

  alias Stone.Accounts.User
  alias Stone.Transactions.Transaction

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "checking_accounts" do
    field :balance, :float
    field :number, :string

    belongs_to :user, User

    has_many :transactions, Transaction

    timestamps()
  end

  @required_create_fields ~w(balance user_id)a

  @required_update_fields ~w(balance)a

  @doc false
  def create_changeset(attrs) do
    %__MODULE__{}
    |> cast(attrs, @required_create_fields)
    |> validate_required(@required_create_fields)
    |> maybe_create_checking_account_number()
    |> unique_constraint(:number)
  end

  def update_changeset(checking_account, attrs) do
    checking_account
    |> cast(attrs, @required_update_fields)
    |> validate_required(@required_update_fields)
  end

  def create_checking_account_number do
    :io_lib.format("~8..0B", [:rand.uniform(100_000_000) - 1]) |> List.to_string()
  end

  defp maybe_create_checking_account_number(
         %Ecto.Changeset{valid?: true, changes: %{number: nil}} = changeset
       ) do
    change(changeset, %{number: create_checking_account_number()})
  end

  defp maybe_create_checking_account_number(changeset), do: changeset
end
