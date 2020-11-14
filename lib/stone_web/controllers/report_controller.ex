defmodule StoneWeb.ReportController do
  use StoneWeb, :controller

  alias Stone.Reports
  alias Stone.Reports.Report

  action_fallback StoneWeb.FallbackController

  def day(conn, _params) do
    user = Guardian.Plug.current_resource(conn)

    Reports.report_by_day(user.checking_account)
    |> response(conn)
  end

  def month(conn, _params) do
    user = Guardian.Plug.current_resource(conn)

    Reports.total_report_by_month(user.checking_account)
    |> response(conn)
  end

  def year(conn, _params) do
    user = Guardian.Plug.current_resource(conn)

    Reports.total_report_by_year(user.checking_account)
    |> response(conn)
  end

  def total(conn, _params) do
    user = Guardian.Plug.current_resource(conn)

    Reports.total_report(user.checking_account)
    |> response(conn)
  end

  defp response(response, conn) do
    case response do
      %Report{} = report ->
        conn
        |> put_status(:ok)
        |> render("report.json", report: report)

      error ->
        error
    end
  end
end
