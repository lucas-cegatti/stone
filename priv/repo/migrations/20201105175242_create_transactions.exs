defmodule Stone.Repo.Migrations.CreateTransactions do
  use Ecto.Migration

  def change do
    create table(:transactions, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :amount, :integer
      add :type, :string
      add :destination, :string
      add :checking_account_id, references(:checking_accounts, on_delete: :nothing, type: :binary_id)

      timestamps()
    end

    create index(:transactions, [:checking_account_id])
  end
end
