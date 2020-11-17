defmodule Stone.Reports.ReportError do
  @type t() :: %__MODULE__{
          code: String.t(),
          message: String.t(),
          plug_status: integer()
        }

  defexception [:code, :message, :plug_status]

  def empty_ledger_balance do
    %__MODULE__{
      code: "R0001",
      message: "Empty ledger balance found.",
      plug_status: 422
    }
  end

  def account_number_not_found(account_number) do
    %__MODULE__{
      code: "R0002",
      message: "Account number, #{account_number}, not found.",
      plug_status: 422
    }
  end
end
