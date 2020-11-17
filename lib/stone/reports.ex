defmodule Stone.Reports do
  @moduledoc """
  The Reports context.
  """

  import Ecto.Query, warn: false

  alias Stone.Accounts.CheckingAccount
  alias Stone.Reports.{Report, ReportError}
  alias Stone.Transactions.Ledgers

  @doc """
  Gets the total transactions of the day of the given checking account
  """
  def report_by_day(%CheckingAccount{number: number}) do
    Ledgers.take_ledgers_balance(number, 1)
    |> reduce_ledger_balances_to_total()
    |> ledger_balances_to_report()
  end

  @doc """
  Gets the total transactions of the month of the given checking account
  """
  def total_report_by_month(%CheckingAccount{number: number}) do
    Ledgers.take_ledgers_balance(number, 30)
    |> reduce_ledger_balances_to_total()
    |> ledger_balances_to_report()
  end

  @doc """
  Gets the total transactions of the year of the given checking account
  """
  def total_report_by_year(%CheckingAccount{number: number}) do
    Ledgers.take_ledgers_balance(number, 365)
    |> reduce_ledger_balances_to_total()
    |> ledger_balances_to_report()
  end

  @doc """
  Gets the total transactions of all balances of the given checking account
  """
  def total_report(%CheckingAccount{number: number}) do
    Ledgers.take_ledgers_balance(number, 0)
    |> reduce_ledger_balances_to_total()
    |> ledger_balances_to_report()
  end

  defp reduce_ledger_balances_to_total([]), do: ReportError.empty_ledger_balance()

  defp reduce_ledger_balances_to_total(ledger_balances) do
    ledger_balances
    |> Enum.reduce(%{}, fn {_date, ledger_balance, ledger_events}, acc ->
      total_credits = ledger_balance.total_credits
      total_debits = ledger_balance.total_debits
      total = ledger_balance.total

      acc
      |> Map.update(:total_credits, total_credits, &(&1 + total_credits))
      |> Map.update(:total_debits, total_debits, &(&1 + total_debits))
      |> Map.update(:total, total, &(&1 + total))
      |> Map.update(:ledger_events, ledger_events, &(&1 ++ ledger_events))
    end)
  end

  defp ledger_balances_to_report(%ReportError{} = error), do: error

  defp ledger_balances_to_report(ledger_balances) do
    Report.ledger_balance_to_report(ledger_balances)
  end
end
