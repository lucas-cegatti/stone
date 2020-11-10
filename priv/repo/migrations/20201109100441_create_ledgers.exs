defmodule Stone.Repo.Migrations.CreateLedgers do
  use Ecto.Migration

  def up do
    create table(:ledger_events, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :number, :integer
      add :amount, :bigint
      add :type, :string
      add :description, :string
      add :event_date, :utc_datetime

      add :checking_account_id,
          references(:checking_accounts, on_delete: :nothing, type: :binary_id)

      timestamps()
    end

    create index(:ledger_events, [:checking_account_id])

    execute "select setval(pg_get_serial_sequence('ledger_events', 'number'), 0)"
  end

  def down do
    drop index(:ledger_events, [:checking_account_id])
    drop table(:ledger_events)
  end
end
