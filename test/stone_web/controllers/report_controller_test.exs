defmodule StoneWeb.ReportControllerTest do
  use StoneWeb.ConnCase

  import Stone.Guardian

  alias Stone.{Accounts, Transactions}

  @initial_credit Money.new(100_000) |> Money.to_string()
  @zero Money.new(0) |> Money.to_string()

  describe "Authorized" do
    setup [:setup_checking_account, :setup_conn_headers]

    test "GET /reports/day returns valid response", %{conn: conn} do
      conn = get(conn, Routes.report_path(conn, :day))

      assert %{
               "total_credits" => _total_credits,
               "total_debits" => _total_debits,
               "total" => _total
             } = json_response(conn, 200)
    end

    test "GET /reports/day returns the initial credit", %{conn: conn} do
      conn = get(conn, Routes.report_path(conn, :day))

      assert %{
               "total_credits" => total_credits,
               "total_debits" => total_debits,
               "total" => total
             } = json_response(conn, 200)

      assert total_credits == @initial_credit
      assert total == @initial_credit
      assert total_debits == @zero
    end

    test "GET /reports/day afert a successfull transaction returns correct data", %{
      conn: conn,
      user: user
    } do
      make_transaction(user, 1_000)
      debit = Money.new(1_000) |> Money.to_string()

      conn = get(conn, Routes.report_path(conn, :day))

      assert %{
               "total_credits" => total_credits,
               "total_debits" => total_debits,
               "total" => _total
             } = json_response(conn, 200)

      assert total_credits == @initial_credit
      assert total_debits == debit
    end

    test "GET /reports/month returns valid response", %{conn: conn} do
      conn = get(conn, Routes.report_path(conn, :month))

      assert %{
               "total_credits" => _total_credits,
               "total_debits" => _total_debits,
               "total" => _total
             } = json_response(conn, 200)
    end

    test "GET /reports/month returns the initial credit", %{conn: conn} do
      conn = get(conn, Routes.report_path(conn, :month))

      assert %{
               "total_credits" => total_credits,
               "total_debits" => total_debits,
               "total" => total
             } = json_response(conn, 200)

      assert total_credits == @initial_credit
      assert total == @initial_credit
      assert total_debits == @zero
    end

    test "GET /reports/month afert a successfull transaction returns correct data", %{
      conn: conn,
      user: user
    } do
      make_transaction(user, 1_000)
      debit = Money.new(1_000) |> Money.to_string()

      conn = get(conn, Routes.report_path(conn, :month))

      assert %{
               "total_credits" => total_credits,
               "total_debits" => total_debits,
               "total" => _total
             } = json_response(conn, 200)

      assert total_credits == @initial_credit
      assert total_debits == debit
    end

    test "GET /reports/year returns valid response", %{conn: conn} do
      conn = get(conn, Routes.report_path(conn, :year))

      assert %{
               "total_credits" => _total_credits,
               "total_debits" => _total_debits,
               "total" => _total
             } = json_response(conn, 200)
    end

    test "GET /reports/year returns the initial credit", %{conn: conn} do
      conn = get(conn, Routes.report_path(conn, :year))

      assert %{
               "total_credits" => total_credits,
               "total_debits" => total_debits,
               "total" => total
             } = json_response(conn, 200)

      assert total_credits == @initial_credit
      assert total == @initial_credit
      assert total_debits == @zero
    end

    test "GET /reports/year afert a successfull transaction returns correct data", %{
      conn: conn,
      user: user
    } do
      make_transaction(user, 1_000)
      debit = Money.new(1_000) |> Money.to_string()

      conn = get(conn, Routes.report_path(conn, :year))

      assert %{
               "total_credits" => total_credits,
               "total_debits" => total_debits,
               "total" => _total
             } = json_response(conn, 200)

      assert total_credits == @initial_credit
      assert total_debits == debit
    end

    test "GET /reports/total returns valid response", %{conn: conn} do
      conn = get(conn, Routes.report_path(conn, :total))

      assert %{
               "total_credits" => _total_credits,
               "total_debits" => _total_debits,
               "total" => _total
             } = json_response(conn, 200)
    end

    test "GET /reports/total returns the initial credit", %{conn: conn} do
      conn = get(conn, Routes.report_path(conn, :total))

      assert %{
               "total_credits" => total_credits,
               "total_debits" => total_debits,
               "total" => total
             } = json_response(conn, 200)

      assert total_credits == @initial_credit
      assert total == @initial_credit
      assert total_debits == @zero
    end

    test "GET /reports/total afert a successfull transaction returns correct data", %{
      conn: conn,
      user: user
    } do
      make_transaction(user, 1_000)
      debit = Money.new(1_000) |> Money.to_string()

      conn = get(conn, Routes.report_path(conn, :total))

      assert %{
               "total_credits" => total_credits,
               "total_debits" => total_debits,
               "total" => _total
             } = json_response(conn, 200)

      assert total_credits == @initial_credit
      assert total_debits == debit
    end
  end

  describe "Unauthorized" do
    setup [:setup_checking_account]

    test "GET /reports/day with invalid token returns 401 unaunthorized", %{conn: conn} do
      conn =
        conn
        |> put_req_header("accept", "application/json")
        |> put_req_header("authorization", "Bearer " <> "invalid")
        |> get(Routes.report_path(conn, :day))

      assert %{"error" => "invalid_token"} = json_response(conn, 401)
    end

    test "GET /reports/month with invalid token returns 401 unaunthorized", %{conn: conn} do
      conn =
        conn
        |> put_req_header("accept", "application/json")
        |> put_req_header("authorization", "Bearer " <> "invalid")
        |> get(Routes.report_path(conn, :month))

      assert %{"error" => "invalid_token"} = json_response(conn, 401)
    end

    test "GET /reports/year with invalid token returns 401 unaunthorized", %{conn: conn} do
      conn =
        conn
        |> put_req_header("accept", "application/json")
        |> put_req_header("authorization", "Bearer " <> "invalid")
        |> get(Routes.report_path(conn, :year))

      assert %{"error" => "invalid_token"} = json_response(conn, 401)
    end

    test "GET /reports/total with invalid token returns 401 unaunthorized", %{conn: conn} do
      conn =
        conn
        |> put_req_header("accept", "application/json")
        |> put_req_header("authorization", "Bearer " <> "invalid")
        |> get(Routes.report_path(conn, :total))

      assert %{"error" => "invalid_token"} = json_response(conn, 401)
    end
  end

  defp make_transaction(user, amount) do
    Transactions.withdrawal(
      amount,
      user.checking_account,
      Transactions.get_transaction_id_for_checking_account()
    )
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

  defp setup_conn_headers(context) do
    {:ok, token, _} = encode_and_sign(context[:user], %{}, token_type: :access)

    conn =
      context[:conn]
      |> put_req_header("accept", "application/json")
      |> put_req_header("authorization", "Bearer " <> token)

    [conn: conn]
  end
end
