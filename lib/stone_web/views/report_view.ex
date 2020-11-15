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
    %{
      total_credits: report.total_credits,
      total_debits: report.total_debits,
      total: report.total,
      transactions: render_many(report.ledger_events, ReportView, "transaction.json")
    }
  end

  def render("transaction.json", %{report: ledger_event}) do
    %{
      id: ledger_event.id,
      amount: ledger_event.amount,
      type: ledger_event.type,
      description: ledger_event.description,
      event_date: ledger_event.event_date
    }
  end
end
