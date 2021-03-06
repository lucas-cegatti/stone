defmodule StoneWeb.TransactionView do
  use StoneWeb, :view
  alias Stone.Transactions.TransactionError
  alias StoneWeb.TransactionView

  def render("index.json", %{transactions: transactions}) do
    %{data: render_many(transactions, TransactionView, "transaction.json")}
  end

  def render("show.json", %{transaction: transaction}) do
    %{data: render_one(transaction, TransactionView, "transaction.json")}
  end

  def render("error.json", %{error: %TransactionError{code: code, message: message}}) do
    %{
      error: %{code: code, message: message}
    }
  end

  def render("transaction.json", %{ledger_event: ledger_event}) do
    %{
      id: ledger_event.id,
      amount: ledger_event.amount,
      type: ledger_event.type,
      description: ledger_event.description
    }
  end

  def render("transaction_id.json", %{transaction_id: transaction_id}) do
    %{
      transaction_id: transaction_id
    }
  end
end
