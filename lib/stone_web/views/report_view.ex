defmodule StoneWeb.ReportView do
  use StoneWeb, :view
  alias StoneWeb.ReportView

  alias Stone.Reports.{ReportError, Report}

  def render("index.json", %{reports: reports}) do
    %{data: render_many(reports, ReportView, "report.json")}
  end

  def render("show.json", %{report: report}) do
    %{data: render_one(report, ReportView, "report.json")}
  end

  def render("error.json", %{error: %ReportError{code: code, message: message}}) do
    %{
      error: %{code: code, message: message}
    }
  end

  def render("report.json", %{report: %Report{} = report}) do
    %{total_credits: report.total_credits, total_debits: report.total_debits, total: report.total}
  end
end
