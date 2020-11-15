defmodule Stone.Reports.Report do
  @moduledoc """
  Report module that converts a ledger balance into a user friendly report.
  """
  alias Stone.Transactions.LedgerEvent

  defstruct date: "", total_credits: "", total_debits: "", total: "", ledger_events: []

  @type t :: %__MODULE__{
          total_credits: String.t(),
          total_debits: String.t(),
          total: String.t(),
          ledger_events: []
        }

  @doc """
  Transform a list of ledger balances into `Stone.Reports.Report` structure
  """
  def ledger_balance_to_report(ledger_balances) when is_list(ledger_balances) do
    ledger_balances
    |> Enum.map(&ledger_balance_to_report/1)
  end

  def ledger_balance_to_report(%{} = ledger_balance) do
    ledger_balance_to_report({Date.utc_today(), ledger_balance, ledger_balance.ledger_events})
  end

  def ledger_balance_to_report(
        {%Date{} = date,
         %{
           total_credits: total_credits,
           total_debits: total_debits,
           total: total
         }, ledger_events}
      ) do
    total_credits = Money.new(total_credits)
    total_debits = Money.new(total_debits)
    total = Money.new(total)

    %__MODULE__{
      date: :io_lib.format("~2..0B/~2..0B/~4..0B", [date.day, date.month, date.year]),
      total_credits: Money.to_string(total_credits),
      total_debits: Money.to_string(total_debits),
      total: Money.to_string(total),
      ledger_events: parse_ledger_events(ledger_events)
    }
  end

  defp parse_ledger_events(ledger_events) do
    ledger_events
    |> Enum.map(fn %LedgerEvent{} = ledger_event ->
      amount =
        case ledger_event.type do
          :credit ->
            Money.new(ledger_event.amount) |> Money.to_string()

          :debit ->
            Money.new(ledger_event.amount * -1) |> Money.to_string()
        end

      event_date =
        :io_lib.format("~2..0B/~2..0B/~4..0B ~2..0B:~2..0B:~2..0B", [
          ledger_event.event_date.day,
          ledger_event.event_date.month,
          ledger_event.event_date.year,
          ledger_event.event_date.hour,
          ledger_event.event_date.minute,
          ledger_event.event_date.second
        ])

      %{
        id: ledger_event.id,
        amount: amount,
        type: ledger_event.type,
        description: ledger_event.description,
        event_date: event_date
      }
    end)
  end
end
