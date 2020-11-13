defmodule StoneWeb.ReportController do
  use StoneWeb, :controller

  alias Stone.Reports
  alias Stone.Reports.Report

  action_fallback StoneWeb.FallbackController

end
