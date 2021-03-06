defmodule StoneWeb.FallbackController do
  @moduledoc """
  Translates controller action results into valid `Plug.Conn` responses.

  See `Phoenix.Controller.action_fallback/1` for more details.
  """
  use StoneWeb, :controller

  alias Stone.Reports.ReportError
  alias Stone.Transactions.TransactionError

  # This clause handles errors returned by Ecto's insert/update/delete.
  def call(conn, {:error, %Ecto.Changeset{} = changeset}) do
    conn
    |> put_status(:unprocessable_entity)
    |> put_view(StoneWeb.ChangesetView)
    |> render("error.json", changeset: changeset)
  end

  # This clause is an example of how to handle resources that cannot be found.
  def call(conn, {:error, :not_found}) do
    conn
    |> put_status(:not_found)
    |> put_view(StoneWeb.ErrorView)
    |> render(:"404")
  end

  def call(conn, {:error, :unauthorized}) do
    conn
    |> put_status(:unauthorized)
    |> json(%{error: "Authentication Failed"})
  end

  def call(conn, %TransactionError{plug_status: plug_status} = error) do
    conn
    |> put_status(plug_status)
    |> put_view(StoneWeb.TransactionView)
    |> render("error.json", %{error: error})
  end

  def call(conn, %ReportError{plug_status: plug_status} = error) do
    conn
    |> put_status(plug_status)
    |> put_view(StoneWeb.ReportView)
    |> render("error.json", %{error: error})
  end
end
