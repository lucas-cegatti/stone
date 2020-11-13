defmodule Stone.Reports.Report do
  @moduledoc """
  Report module that converts a ledger balance into a user friendly report.
  """
  defstruct date: "", total_credits: "", total_debits: "", total: ""

  @type t :: %__MODULE__{
          total_credits: String.t(),
          total_debits: String.t(),
          total: String.t()
        }

  @doc """
  Transform a list of ledger balances into `Stone.Reports.Report` structure
  """
  def ledger_balance_to_report(ledger_balances) when is_list(ledger_balances) do
    ledger_balances
    |> Enum.map(&ledger_balance_to_report/1)
  end

  def ledger_balance_to_report(%{} = ledger_balance) do
    ledger_balance_to_report({Date.utc_today(), ledger_balance, []})
  end

  def ledger_balance_to_report(
        {%Date{} = date,
         %{
           total_credits: total_credits,
           total_debits: total_debits,
           total: total
         }, _ledger_events}
      ) do
    total_credits = Money.new(total_credits)
    total_debits = Money.new(total_debits)
    total = Money.new(total)

    %__MODULE__{
      date: :io_lib.format("~2..0B/~2..0B/~4..0B", [date.day, date.month, date.year]),
      total_credits: Money.to_string(total_credits),
      total_debits: Money.to_string(total_debits),
      total: Money.to_string(total)
    }
  end
end
