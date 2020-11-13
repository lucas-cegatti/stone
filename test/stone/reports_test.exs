defmodule Stone.ReportsTest do
  use Stone.DataCase

  alias Stone.{Reports, Accounts}
  alias Stone.Accounts.CheckingAccount
  alias Stone.Reports.{Report, ReportError}

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

      assert %ReportError{code: "R0001", message: message} =
               Reports.report_by_day(checking_account)
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

    [checking_account: user.checking_account]
  end
end
