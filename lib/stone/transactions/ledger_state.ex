defmodule Stone.Transactions.LedgerState do
  alias Stone.Transactions.LedgerEvent

  @type ledger_balance :: %{
          total_credits: integer(),
          total_debits: integer(),
          total: integer()
        }

  defstruct balance: 0, ledger_events: [], ledger_balances: []

  @type t :: %__MODULE__{
          balance: integer(),
          ledger_events: [LedgerEvent.t()],
          ledger_balances: [{Date.t(), ledger_balance(), ledger_events: [LedgerEvent.t()]}]
        }
end
