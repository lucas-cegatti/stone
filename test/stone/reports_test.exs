defmodule Stone.ReportsTest do
  use Stone.DataCase

  alias Stone.Accounts.CheckingAccount
  alias Stone.Reports.{Report, ReportError}
  alias Stone.{Reports, Accounts, Transactions}

  describe "day reports" do
    setup [:setup_checking_account]

    test "report_by_day/1 with initial account should return report data", %{
      checking_account: checking_account
    } do
      balance = Money.new(checking_account.balance) |> Money.to_string()
      zero = Money.new(0) |> Money.to_string()

      assert %Report{} = report = Reports.report_by_day(checking_account)

      assert report.total_credits == balance
      assert report.total_debits == zero
      assert report.total == balance
    end

    test "report_by_day/1 with invalid account number return report error R0001", %{
      checking_account: checking_account
    } do
      checking_account = %CheckingAccount{checking_account | number: "invalid"}

      assert %ReportError{code: "R0001", message: _message} =
               Reports.report_by_day(checking_account)
    end
  end

  describe "month reports" do
    setup [:setup_checking_account, :setup_month_transactions]

    test "total_report_by_month/1 with initial account and transactions should return report data",
         %{
           checking_account: checking_account,
           totals: _totals
         } do
      assert %Report{} = Reports.total_report_by_month(checking_account)
    end

    test "total_report_by_month/1 with invalid account number return report error R0001", %{
      checking_account: checking_account
    } do
      checking_account = %CheckingAccount{checking_account | number: "invalid"}

      assert %ReportError{code: "R0001", message: _message} =
               Reports.total_report_by_month(checking_account)
    end
  end

  describe "year reports" do
    setup [:setup_checking_account, :setup_month_transactions]

    test "total_report_by_year/1 with initial account and transactions should return report data",
         %{
           checking_account: checking_account,
           totals: _totals
         } do
      assert %Report{} = Reports.total_report_by_year(checking_account)
    end

    test "total_report_by_year/1 with invalid account number return report error R0001", %{
      checking_account: checking_account
    } do
      checking_account = %CheckingAccount{checking_account | number: "invalid"}

      assert %ReportError{code: "R0001", message: _message} =
               Reports.total_report_by_year(checking_account)
    end
  end

  describe "total reports" do
    setup [:setup_checking_account, :setup_month_transactions]

    test "total_report/1 with initial account and transactions should return report data",
         %{
           checking_account: checking_account,
           totals: _totals
         } do
      assert %Report{} = Reports.total_report(checking_account)
    end

    test "total_report/1 with invalid account number return report error R0001", %{
      checking_account: checking_account
    } do
      checking_account = %CheckingAccount{checking_account | number: "invalid"}

      assert %ReportError{code: "R0001", message: _message} =
               Reports.total_report(checking_account)
    end
  end

  defp setup_checking_account(_context) do
    valid_user_attrs = %{
      email: "foo@bar.com",
      name: "Foo Bar",
      password: "passwordHash",
      password_confirmation: "passwordHash"
    }

    initial = ~D[2020-01-01]
    date_time = DateTime.utc_now()
    {:ok, event_date} = DateTime.new(initial, DateTime.to_time(date_time))

    {:ok, user} =
      valid_user_attrs |> Accounts.create_user_with_checking_account(event_date: event_date)

    [checking_account: user.checking_account]
  end

  defp setup_month_transactions(context) do
    initial = ~D[2020-01-01]
    date_range = Date.range(initial, Date.add(initial, 30))

    checking_account = context.checking_account

    totals = setup_transactions_by_date_range(date_range, checking_account)

    [totals: totals]
  end

  defp setup_transactions_by_date_range(date_range, checking_account) do
    acc = %{
      total: checking_account.balance,
      total_credits: checking_account.balance,
      total_debits: 0
    }

    date_range
    |> Enum.reduce(acc, fn date, acc ->
      date_time = DateTime.utc_now()
      {:ok, event_date} = DateTime.new(date, DateTime.to_time(date_time))

      transaction_id = Transactions.get_transaction_id_for_checking_account()

      transaction_amount = Enum.random(1_000..10_000)

      Transactions.withdrawal(transaction_amount, checking_account, transaction_id,
        event_date: event_date
      )

      Map.update(acc, :total_debits, 0, &(&1 + transaction_amount))
      |> Map.update(:total, 0, &(&1 + transaction_amount))
    end)
  end
end
