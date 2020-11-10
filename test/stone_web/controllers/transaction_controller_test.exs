defmodule StoneWeb.TransactionControllerTest do
  use StoneWeb.ConnCase
  import Stone.Guardian

  alias Stone.Accounts
  alias Stone.Transactions

  describe "/withdrawal" do
    setup [:setup_checking_account, :setup_conn_headers]

    test "POST /withdrawal with valid data returns 201 created", %{conn: conn} do
      transaction_id = Transactions.get_transaction_id_for_checking_account()

      conn =
        post(conn, Routes.transaction_path(conn, :withdrawal),
          amount: 100,
          transaction_id: transaction_id
        )

      assert %{"id" => id, "amount" => amount, "type" => type, "description" => description} =
               json_response(conn, 201)
    end

    test "POST /withdrawal with valid data creates a checking account ledger event", %{
      conn: conn,
      checking_account: checking_account
    } do
      transaction_id = Transactions.get_transaction_id_for_checking_account()

      conn =
        post(conn, Routes.transaction_path(conn, :withdrawal),
          amount: 100,
          transaction_id: transaction_id
        )

      assert %{"id" => id, "amount" => amount, "type" => type, "description" => description} =
               json_response(conn, 201)

      checking_account = Accounts.get_checking_acount_by_id(checking_account.id)
      assert Enum.any?(checking_account.ledger_events, &(&1.id == id))
    end

    test "POST /withdrawal with valid data return the correct processed data at the response", %{
      conn: conn,
      checking_account: _checking_account
    } do
      transaction_id = Transactions.get_transaction_id_for_checking_account()

      conn =
        post(conn, Routes.transaction_path(conn, :withdrawal),
          amount: 100,
          transaction_id: transaction_id
        )

      assert %{"id" => id, "amount" => amount, "type" => type, "description" => description} =
               json_response(conn, 201)

      assert amount == 100
      assert type == "debit"
      assert String.contains?(description, "Withdrawal from checking account")
    end

    test "POST /withdrawal with negative amount should return an error response", %{
      conn: conn,
      checking_account: _checking_account
    } do
      transaction_id = Transactions.get_transaction_id_for_checking_account()

      conn =
        post(conn, Routes.transaction_path(conn, :withdrawal),
          amount: -100,
          transaction_id: transaction_id
        )

      assert %{"error" => %{"code" => "T0005", "message" => message}} = json_response(conn, 422)

      assert String.contains?(message, "-100")
    end

    test "POST /withdrawal with invalid amount should return an error response", %{
      conn: conn,
      checking_account: _checking_account
    } do
      transaction_id = Transactions.get_transaction_id_for_checking_account()

      conn =
        post(conn, Routes.transaction_path(conn, :withdrawal),
          amount: "a",
          transaction_id: transaction_id
        )

      assert %{"error" => %{"code" => "T0002", "message" => message}} = json_response(conn, 422)

      assert String.contains?(
               message,
               "Invalid Transaction Amount given a. Check if the parameter is of integer type."
             )
    end

    test "POST /withdrawal with amount leading to negative balance returns an error", %{
      conn: conn,
      checking_account: _checking_account
    } do
      transaction_id = Transactions.get_transaction_id_for_checking_account()

      conn =
        post(conn, Routes.transaction_path(conn, :withdrawal),
          amount: 100_001,
          transaction_id: transaction_id
        )

      assert %{"error" => %{"code" => "T0003", "message" => message}} = json_response(conn, 422)

      assert String.contains?(message, "100001")
    end

    test "POST /withdrawal using the same transaction id twice returns an error", %{
      conn: conn,
      checking_account: _checking_account
    } do
      transaction_id = Transactions.get_transaction_id_for_checking_account()

      conn =
        post(conn, Routes.transaction_path(conn, :withdrawal),
          amount: 100,
          transaction_id: transaction_id
        )

      assert %{"id" => id, "amount" => amount, "type" => type, "description" => description} =
               json_response(conn, 201)

      conn =
        post(conn, Routes.transaction_path(conn, :withdrawal),
          amount: 100,
          transaction_id: transaction_id
        )

      assert %{"error" => %{"code" => "T0001", "message" => message}} = json_response(conn, 401)
      String.contains?(message, "Invalid Transaction ID given #{transaction_id}")
    end

    test "POST /withdrawal using an invalid transaction id returns an error", %{
      conn: conn,
      checking_account: _checking_account
    } do
      transaction_id = Ecto.UUID.generate()

      conn =
        post(conn, Routes.transaction_path(conn, :withdrawal),
          amount: 100,
          transaction_id: transaction_id
        )

      assert %{"error" => %{"code" => "T0001", "message" => message}} = json_response(conn, 401)
      String.contains?(message, "Invalid Transaction ID given #{transaction_id}")
    end

    test "POST /withdrawal allows to withdrawal all checking account balance leading it to 0", %{
      conn: conn,
      checking_account: checking_account
    } do
      transaction_id = Transactions.get_transaction_id_for_checking_account()

      conn =
        post(conn, Routes.transaction_path(conn, :withdrawal),
          amount: 100_000,
          transaction_id: transaction_id
        )

      assert %{"id" => id, "amount" => amount, "type" => type, "description" => description} =
               json_response(conn, 201)

      assert amount == 100_000
      checking_account = Accounts.get_checking_acount_by_id(checking_account.id)
      assert checking_account.balance == 0
    end
  end

  describe "/transfer" do
    setup [:setup_checking_account, :setup_second_checking_account, :setup_conn_headers]

    test "POST /transfer with valid data returns 201 success", %{
      conn: conn,
      checking_account: _checking_account,
      second_checking_account: second_checking_account
    } do
      transaction_id = Transactions.get_transaction_id_for_checking_account()

      conn =
        post(conn, Routes.transaction_path(conn, :transfer),
          amount: 100,
          destination_account_number: second_checking_account.number,
          transaction_id: transaction_id
        )

      assert %{"id" => id, "amount" => amount, "type" => type, "description" => description} =
               json_response(conn, 201)

      assert amount == 100
    end

    test "POST /transfer with valid data returns the checking account ledger of the logged user",
         %{
           conn: conn,
           checking_account: checking_account,
           second_checking_account: second_checking_account
         } do
      transaction_id = Transactions.get_transaction_id_for_checking_account()

      conn =
        post(conn, Routes.transaction_path(conn, :transfer),
          amount: 100,
          destination_account_number: second_checking_account.number,
          transaction_id: transaction_id
        )

      assert %{"id" => id, "amount" => amount, "type" => type, "description" => description} =
               json_response(conn, 201)

      checking_account = Accounts.get_checking_acount_by_id(checking_account.id)
      assert Enum.any?(checking_account.ledger_events, &(&1.id == id))
    end

    test "POST /transfer with valid data credits the destination account number", %{
      conn: conn,
      checking_account: _checking_account,
      second_checking_account: second_checking_account
    } do
      transaction_id = Transactions.get_transaction_id_for_checking_account()

      conn =
        post(conn, Routes.transaction_path(conn, :transfer),
          amount: 100,
          destination_account_number: second_checking_account.number,
          transaction_id: transaction_id
        )

      assert %{"id" => id, "amount" => amount, "type" => type, "description" => description} =
               json_response(conn, 201)

      second_checking_account = Accounts.get_checking_acount_by_id(second_checking_account.id)
      assert 2 == length(second_checking_account.ledger_events)
      assert second_checking_account.balance == 100_100
    end

    test "POST /transfer with invalid destination account number returns an error", %{
      conn: conn,
      checking_account: _checking_account,
      second_checking_account: _second_checking_account
    } do
      transaction_id = Transactions.get_transaction_id_for_checking_account()

      conn =
        post(conn, Routes.transaction_path(conn, :transfer),
          amount: 100,
          destination_account_number: "000010",
          transaction_id: transaction_id
        )

      assert %{"error" => %{"code" => "T0004", "message" => message}} = json_response(conn, 422)
    end

    test "POST /transfer with negative amount should return an error", %{
      conn: conn,
      checking_account: _checking_account,
      second_checking_account: second_checking_account
    } do
      transaction_id = Transactions.get_transaction_id_for_checking_account()

      conn =
        post(conn, Routes.transaction_path(conn, :transfer),
          amount: -100,
          destination_account_number: second_checking_account.number,
          transaction_id: transaction_id
        )

      assert %{"error" => %{"code" => "T0005", "message" => message}} = json_response(conn, 422)
    end

    test "POST /transfer to same account number returns an error", %{
      conn: conn,
      checking_account: checking_account,
      second_checking_account: _second_checking_account
    } do
      transaction_id = Transactions.get_transaction_id_for_checking_account()

      conn =
        post(conn, Routes.transaction_path(conn, :transfer),
          amount: 100,
          destination_account_number: checking_account.number,
          transaction_id: transaction_id
        )

      assert %{"error" => %{"code" => "T0006", "message" => message}} = json_response(conn, 422)
    end

    test "POST /transfer with invalid non integer amount returns an error", %{
      conn: conn,
      checking_account: _checking_account,
      second_checking_account: second_checking_account
    } do
      transaction_id = Transactions.get_transaction_id_for_checking_account()

      conn =
        post(conn, Routes.transaction_path(conn, :transfer),
          amount: "a",
          destination_account_number: second_checking_account.number,
          transaction_id: transaction_id
        )

      assert %{"error" => %{"code" => "T0002", "message" => message}} = json_response(conn, 422)
    end

    test "POST /transfer should not lead to negative balance on source account", %{
      conn: conn,
      checking_account: _checking_account,
      second_checking_account: second_checking_account
    } do
      transaction_id = Transactions.get_transaction_id_for_checking_account()

      conn =
        post(conn, Routes.transaction_path(conn, :transfer),
          amount: 100_001,
          destination_account_number: second_checking_account.number,
          transaction_id: transaction_id
        )

      assert %{"error" => %{"code" => "T0003", "message" => message}} = json_response(conn, 422)
    end

    test "POST /transfer should allow to transfer all funds", %{
      conn: conn,
      checking_account: checking_account,
      second_checking_account: second_checking_account
    } do
      transaction_id = Transactions.get_transaction_id_for_checking_account()

      conn =
        post(conn, Routes.transaction_path(conn, :transfer),
          amount: 100_000,
          destination_account_number: second_checking_account.number,
          transaction_id: transaction_id
        )

      assert %{"id" => id, "amount" => amount, "type" => type, "description" => description} =
               json_response(conn, 201)

      checking_account = Accounts.get_checking_acount_by_id(checking_account.id)
      second_checking_account = Accounts.get_checking_acount_by_id(second_checking_account.id)
      assert checking_account.balance == 0
      assert assert second_checking_account.balance == 200_000
    end
  end

  defp setup_checking_account(_context) do
    valid_user_attrs = %{
      email: "foo@bar.com",
      name: "Foo Bar",
      password: "passwordHash",
      password_confirmation: "passwordHash"
    }

    {:ok, user} = valid_user_attrs |> Accounts.create_user_with_checking_account()

    [checking_account: user.checking_account, user: user]
  end

  defp setup_second_checking_account(_context) do
    valid_user_attrs = %{
      email: "bar@foo.com",
      name: "Bar Foo",
      password: "passwordHash",
      password_confirmation: "passwordHash"
    }

    {:ok, user} = valid_user_attrs |> Accounts.create_user_with_checking_account()

    [second_checking_account: user.checking_account]
  end

  defp setup_conn_headers(context) do
    {:ok, token, _} = encode_and_sign(context[:user], %{}, token_type: :access)

    conn =
      context[:conn]
      |> put_req_header("accept", "application/json")
      |> put_req_header("authorization", "Bearer " <> token)

    [conn: conn]
  end
end
