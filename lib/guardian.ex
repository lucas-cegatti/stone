defmodule Stone.Guardian do
  @moduledoc """
  This module implements some callbacks used by the `Guardian` module.

  They are referenced and configured at `StoneWeb.Router` line 9
  """
  use Guardian, otp_app: :stone

  alias Stone.Accounts

  @doc """
  Adds the user id to the jwt token
  """
  def subject_for_token(user, _claims) do
    sub = to_string(user.id)
    {:ok, sub}
  end

  def subject_for_token(_, _) do
    {:error, :reason_for_error}
  end

  @doc """
  Retrieves the user from the jwt token claim
  """
  def resource_from_claims(claims) do
    id = claims["sub"]

    resource = Accounts.get_user!(id)

    {:ok, resource}
  end

  def resource_from_claims(_claims) do
    {:error, :reason_for_error}
  end
end
