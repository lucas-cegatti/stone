defmodule Stone.Repo.Migrations.CreateUsers do
  use Ecto.Migration

  def change do
    create table(:users, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :name, :string
      add :password_hash, :string
      add :email, :string

      timestamps()
    end

    create index(:users, [:email], unique: true)
  end
end
