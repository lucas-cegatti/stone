defmodule Stone.Repo.Migrations.CreateCheckingAccounts do
  use Ecto.Migration

  def change do
    create table(:checking_accounts, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :number, :string
      add :balance, :float
      add :user_id, references(:users, on_delete: :nothing, type: :binary_id)

      timestamps()
    end

    create unique_index(:checking_accounts, [:number])
    create index(:checking_accounts, [:user_id])
  end
end
