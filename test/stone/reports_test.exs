defmodule Stone.ReportsTest do
  use Stone.DataCase

  alias Stone.Accounts.CheckingAccount
  alias Stone.Reports.{Report, ReportError}
  alias Stone.{Accounts, Reports, Transactions}

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
           checking_account: checking_account
         } do
      balance = Money.new(checking_account.balance) |> Money.to_string()
      debits = Money.new(3_000) |> Money.to_string()

      assert %Report{total_debits: total_debits, total_credits: total_credits} =
               Reports.total_report_by_month(checking_account)

      assert total_debits == debits
      assert total_credits == balance
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
    setup [:setup_checking_account, :setup_year_transactions]

    test "total_report_by_year/1 with initial account and transactions should return report data",
         %{
           checking_account: checking_account
         } do
      balance = Money.new(checking_account.balance) |> Money.to_string()
      debits = Money.new(3_000) |> Money.to_string()

      assert %Report{total_debits: total_debits, total_credits: total_credits} =
               Reports.total_report_by_year(checking_account)

      assert total_debits == debits
      assert total_credits == balance
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
    setup [:setup_checking_account, :setup_total_transactions]

    test "total_report/1 with initial account and transactions should return report data",
         %{
           checking_account: checking_account
         } do
      balance = Money.new(checking_account.balance) |> Money.to_string()
      debits = Money.new(4_000) |> Money.to_string()

      assert %Report{total_debits: total_debits, total_credits: total_credits} =
               Reports.total_report(checking_account)

      assert total_debits == debits
      assert total_credits == balance
    end

    test "total_report/1 with invalid account number return report error R0001", %{
      checking_account: checking_account
    } do
      checking_account = %CheckingAccount{checking_account | number: "invalid"}

      assert %ReportError{code: "R0001", message: _message} =
               Reports.total_report(checking_account)
    end
  end

  describe "reports with no balances" do
    setup [:setup_checking_account_with_older_date]

    test "day report with no balances should return a report error R0001", %{
      checking_account: checking_account
    } do
      assert %ReportError{code: "R0001", message: "Empty ledger balance found."} =
               Reports.report_by_day(checking_account)
    end

    test "month report with no balances should return a report error R0001", %{
      checking_account: checking_account
    } do
      assert %ReportError{code: "R0001", message: "Empty ledger balance found."} =
               Reports.total_report_by_month(checking_account)
    end

    test "year report with no balances should return a report error R0001", %{
      checking_account: checking_account
    } do
      assert %ReportError{code: "R0001", message: "Empty ledger balance found."} =
               Reports.total_report_by_year(checking_account)
    end
  end

  defp setup_checking_account_with_older_date(_context) do
    valid_user_attrs = %{
      email: "foo@bar.com",
      name: "Foo Bar",
      password: "passwordHash",
      password_confirmation: "passwordHash"
    }

    initial = Date.utc_today() |> Date.add(-400)
    date_time = DateTime.utc_now()
    {:ok, event_date} = DateTime.new(initial, DateTime.to_time(date_time))

    {:ok, user} =
      valid_user_attrs |> Accounts.create_user_with_checking_account(event_date: event_date)

    [checking_account: user.checking_account]
  end

  defp setup_checking_account(_context) do
    valid_user_attrs = %{
      email: "foo@bar.com",
      name: "Foo Bar",
      password: "passwordHash",
      password_confirmation: "passwordHash"
    }

    initial = Date.utc_today()
    date_time = DateTime.utc_now()
    {:ok, event_date} = DateTime.new(initial, DateTime.to_time(date_time))

    {:ok, user} =
      valid_user_attrs |> Accounts.create_user_with_checking_account(event_date: event_date)

    [checking_account: user.checking_account]
  end

  defp setup_month_transactions(context) do
    checking_account = context.checking_account

    [10, 15, 29]
    |> Enum.each(fn days ->
      date = Date.utc_today() |> Date.add(days * -1)
      date_time = DateTime.utc_now()
      {:ok, event_date} = DateTime.new(date, DateTime.to_time(date_time))

      transaction_id = Transactions.get_transaction_id_for_checking_account()
      Transactions.withdrawal(1_000, checking_account, transaction_id, event_date: event_date)
    end)

    []
  end

  defp setup_year_transactions(context) do
    checking_account = context.checking_account

    [60, 90, 120]
    |> Enum.each(fn days ->
      date = Date.utc_today() |> Date.add(days * -1)
      date_time = DateTime.utc_now()
      {:ok, event_date} = DateTime.new(date, DateTime.to_time(date_time))

      transaction_id = Transactions.get_transaction_id_for_checking_account()
      Transactions.withdrawal(1_000, checking_account, transaction_id, event_date: event_date)
    end)

    []
  end

  defp setup_total_transactions(context) do
    checking_account = context.checking_account

    [60, 90, 120, 420]
    |> Enum.each(fn days ->
      date = Date.utc_today() |> Date.add(days * -1)
      date_time = DateTime.utc_now()
      {:ok, event_date} = DateTime.new(date, DateTime.to_time(date_time))

      transaction_id = Transactions.get_transaction_id_for_checking_account()
      Transactions.withdrawal(1_000, checking_account, transaction_id, event_date: event_date)
    end)

    []
  end
end
