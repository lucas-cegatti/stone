defmodule Stone.Transactions.TransactionIdTest do
  use Stone.DataCase

  alias Stone.Transactions.TransactionId

  describe "transaction ids" do
    test "create/0 should return a valid transaction id" do
      transaction_id = TransactionId.create()

      assert String.match?(
               transaction_id,
               ~r/[0-9a-fA-F]{8}\-[0-9a-fA-F]{4}\-[0-9a-fA-F]{4}\-[0-9a-fA-F]{4}\-[0-9a-fA-F]{12}/
             )
    end

    test "take/1 should return a transaction id and remove it from the stack" do
      transaction_id = TransactionId.create()

      assert {:ok, []} = TransactionId.take(transaction_id)

      assert {:error, :not_found, ^transaction_id} = TransactionId.take(transaction_id)

      assert String.match?(
               transaction_id,
               ~r/[0-9a-fA-F]{8}\-[0-9a-fA-F]{4}\-[0-9a-fA-F]{4}\-[0-9a-fA-F]{4}\-[0-9a-fA-F]{12}/
             )
    end

    test "taks/1 with a random uuid should return error not found" do
      transaction_id = Ecto.UUID.generate()
      assert {:error, :not_found, ^transaction_id} = TransactionId.take(transaction_id)
    end
  end
end
