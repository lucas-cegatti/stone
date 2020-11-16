defmodule Stone.Emails do
  alias Stone.Accounts.User
  alias Stone.Transactions.LedgerEvent

  require Logger

  def send_credit_email(%User{} = user, %LedgerEvent{} = ledger_event) do
    email =
      Phoenix.View.render_to_string(StoneWeb.TransactionView, "credit.html",
        user: user,
        ledger_event: ledger_event
      )

    Logger.warn("Credit Email Sent #{email}")
  end

  def send_debit_email(%User{} = user, %LedgerEvent{} = ledger_event) do
    email =
      Phoenix.View.render_to_string(StoneWeb.TransactionView, "debit.html",
        user: user,
        ledger_event: ledger_event
      )

    Logger.warn("Debit Email Sent #{email}")
  end
end
