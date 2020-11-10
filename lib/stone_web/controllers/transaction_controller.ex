defmodule StoneWeb.TransactionController do
  use StoneWeb, :controller

  alias Stone.Accounts
  alias Stone.Transactions
  # alias Stone.Transactions.Transaction

  action_fallback StoneWeb.FallbackController

  def withdrawal(conn, %{"amount" => amount, "transaction_id" => transaction_id}) do
    user = Guardian.Plug.current_resource(conn)

    Transactions.withdrawal(amount, user.checking_account, transaction_id)
  end

  def transfer(conn, %{
        "amount" => amount,
        "transaction_id" => transaction_id,
        "destination_account_number" => destination_account_number
      }) do
    user = Guardian.Plug.current_resource(conn)

    destination_checking_account =
      Accounts.get_checking_account_by_number(destination_account_number)

    Transactions.transfer(
      amount,
      user.checking_account,
      destination_checking_account,
      transaction_id
    )
  end
end
