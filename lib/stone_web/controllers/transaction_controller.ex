defmodule StoneWeb.TransactionController do
  use StoneWeb, :controller

  alias Stone.Accounts
  alias Stone.Emails
  alias Stone.Transactions
  alias Stone.Transactions.LedgerEvent

  action_fallback StoneWeb.FallbackController

  def withdrawal(conn, %{"amount" => amount, "transaction_id" => transaction_id}) do
    user = Guardian.Plug.current_resource(conn)

    case Transactions.withdrawal(amount, user.checking_account, transaction_id) do
      {:ok, %LedgerEvent{} = ledger_event} ->
        Emails.send_debit_email(user, ledger_event)

        conn
        |> put_status(:created)
        |> render("transaction.json", ledger_event: ledger_event)

      error ->
        error
    end
  end

  def transfer(conn, %{
        "amount" => amount,
        "transaction_id" => transaction_id,
        "destination_account_number" => destination_account_number
      }) do
    user = Guardian.Plug.current_resource(conn)

    destination_checking_account =
      Accounts.get_checking_account_by_number(destination_account_number)

    case Transactions.transfer(
           amount,
           user.checking_account,
           destination_checking_account,
           transaction_id
         ) do
      {:ok, %LedgerEvent{} = ledger_event} ->
        conn
        |> put_status(:created)
        |> render("transaction.json", ledger_event: ledger_event)

      error ->
        error
    end
  end

  def transaction_id(conn, _params) do
    transaction_id = Transactions.get_transaction_id_for_checking_account()

    conn
    |> put_status(:ok)
    |> render("transaction_id.json", transaction_id: transaction_id)
  end
end
