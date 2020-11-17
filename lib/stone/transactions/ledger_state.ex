defmodule Stone.Transactions.LedgerState do
  @moduledoc """
  Struct used at the state of `Stone.Transactions.Ledgers` genserver.

  It stores the base information needed to store the current state of each checking account.

  """
  alias Stone.Transactions.LedgerEvent

  @type ledger_balance :: %{
          total_credits: integer(),
          total_debits: integer(),
          total: integer()
        }

  defstruct balance: 0, ledger_events: [], ledger_balances: []

  @typedoc """
  balance => The current balance of the checking account.
  ledger_events => A list of `Stone.Transactions.LedgerEvent`
  ledger_balances: A list used to group ledger events and balance by day.
  """
  @type t :: %__MODULE__{
          balance: integer(),
          ledger_events: [LedgerEvent.t()],
          ledger_balances: [{Date.t(), ledger_balance(), ledger_events: [LedgerEvent.t()]}]
        }
end
