defmodule Stone.Transactions.TransactionError do
  @type t() :: %__MODULE__{
          code: String.t(),
          message: String.t(),
          plug_status: integer()
        }

  defexception [:code, :message, :plug_status]

  def invalid_transaction_id_error(transaction_id) do
    %__MODULE__{
      code: "T0001",
      message: "Invalid Transaction ID given #{transaction_id}",
      plug_status: 401
    }
  end

  def invalid_transaction_amount(amount) do
    %__MODULE__{
      code: "T0002",
      message: "Invalid Transaction Amount given #{amount}",
      plug_status: 422
    }
  end

  def invalid_transaction_negative_balance_result(amount, balance) do
    %__MODULE__{
      code: "T0003",
      message:
        "Invalid Transaction Amount is Leading do Negative Balance. Amount: #{amount} / Current Balance: #{
          balance
        }",
        plug_status: 422
    }
  end
end
