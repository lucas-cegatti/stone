defmodule Stone.Accounts.User do
  @moduledoc """
  Schema representing a user at the database.
  """
  use Ecto.Schema
  import Ecto.Changeset

  alias Stone.Accounts.CheckingAccount

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "users" do
    field :email, :string
    field :name, :string
    field :password_hash, :string

    field :password, :string, virtual: true
    field :password_confirmation, :string, virtual: true

    has_one :checking_account, CheckingAccount

    timestamps()
  end

  @required_create_fields ~w(name email password password_confirmation)a
  @doc false
  def changeset(user, attrs) do
    user
    |> cast(attrs, @required_create_fields)
    |> validate_required(@required_create_fields)
    |> validate_format(:email, ~r/@/, message: "Invalid Email")
    |> validate_length(:password, min: 6, message: "Minimum password length is 6")
    |> validate_confirmation(:password, message: "Passwords do not match")
    |> put_pass_hash()
    |> unique_constraint(:email)
  end

  defp put_pass_hash(%Ecto.Changeset{valid?: true, changes: %{password: password}} = changeset) do
    change(changeset, Bcrypt.add_hash(password))
  end

  defp put_pass_hash(changeset), do: changeset
end
