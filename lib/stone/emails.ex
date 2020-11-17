defmodule Stone.Emails do
  @moduledoc """
  Module to send email.

  It will only log a string into the logger output.
  """
  alias Stone.Accounts.User
  alias Stone.Transactions.LedgerEvent

  require Logger

  @doc """
  Sends an email when a credit event happens at the account
  """
  def send_credit_email(%User{} = user, %LedgerEvent{} = ledger_event) do
    email =
      Phoenix.View.render_to_string(StoneWeb.TransactionView, "credit.html",
        user: user,
        ledger_event: ledger_event
      )

    Logger.warn("Credit Email Sent #{email}")
  end

  @doc """
  Sends an email when a debit event happens at the account
  """
  def send_debit_email(%User{} = user, %LedgerEvent{} = ledger_event) do
    email =
      Phoenix.View.render_to_string(StoneWeb.TransactionView, "debit.html",
        user: user,
        ledger_event: ledger_event
      )

    Logger.warn("Debit Email Sent #{email}")
  end
end
