defmodule StoneWeb.TransactionController do
  use StoneWeb, :controller

  # alias Stone.Transactions
  # alias Stone.Transactions.Transaction

  action_fallback StoneWeb.FallbackController
end
