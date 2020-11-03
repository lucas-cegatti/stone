defmodule Stone.Accounts.User do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "users" do
    field :email, :string
    field :name, :string
    field :password_hash, :string

    field :password, :string, virtal: true
    field :password_confirmation, :string, virtal: true

    timestamps()
  end

  @required_create_fields ~w(name email password password_confirmation)a
  @doc false
  def changeset(user, attrs) do
    user
    |> cast(attrs, @required_create_fields)
    |> validate_required(@required_create_fields)
    |> validate_confirmation(:password, message: "As senhas não conferem")
    |> put_pass_hash()
    |> unique_constraint(:email)
  end

  defp put_pass_hash(%Ecto.Changeset{valid?: true, changes: %{password: password}} = changeset) do
    change(changeset, Bcrypt.add_hash(password))
  end

  defp put_pass_hash(changeset), do: changeset
end
