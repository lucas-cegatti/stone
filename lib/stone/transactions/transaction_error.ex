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
      message:
        "Invalid Transaction Amount given #{amount}. Check if the parameter is of integer type.",
      plug_status: 422
    }
  end

  def invalid_transaction_negative_balance_result(amount, balance) do
    %__MODULE__{
      code: "T0003",
      message:
        "Invalid Transaction Amount is Leading to Negative Balance. Amount: #{amount} / Current Balance: #{
          balance
        }",
      plug_status: 422
    }
  end

  def invalid_transaction_account_number(account_number) do
    %__MODULE__{
      code: "T0004",
      message: "Invalid account number given #{account_number}",
      plug_status: 422
    }
  end

  def invalid_transaction_amount_negative_integer(amount) do
    %__MODULE__{
      code: "T0005",
      message: "Invalid transaction amount, must be a positive integer, given amount #{amount}",
      plug_status: 422
    }
  end

  def invalid_transaction_transfer_same_destination_account do
    %__MODULE__{
      code: "T0006",
      message: "Invalid transaction transfer, cannot transfer to self.",
      plug_status: 422
    }
  end
end
