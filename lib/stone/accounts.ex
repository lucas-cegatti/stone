defmodule Stone.Accounts do
  @moduledoc """
  The Accounts context.
  """

  import Ecto.Query, warn: false
  alias Stone.Repo

  alias Ecto.Multi
  alias Stone.Guardian
  alias Stone.Accounts.{User, CheckingAccount}

  @doc """
  Returns the list of users.

  ## Examples

      iex> list_users()
      [%User{}, ...]

  """
  def list_users do
    Repo.all(User)
  end

  @doc """
  Gets a single user.

  Raises `Ecto.NoResultsError` if the User does not exist.

  ## Examples

      iex> get_user!(123)
      %User{}

      iex> get_user!(456)
      ** (Ecto.NoResultsError)

  """
  def get_user!(id), do: Repo.get!(User, id)

  @doc """
  Creates a user.

  ## Examples

      iex> create_user(%{field: value})
      {:ok, %User{}}

      iex> create_user(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_user(attrs \\ %{}) do
    %User{}
    |> User.changeset(attrs)
    |> Repo.insert()
  end

  def create_user_with_checking_account(attrs \\ %{}) do
    Multi.new()
    |> Multi.insert(:user, User.changeset(%User{}, attrs))
    |> Multi.insert(:checking_account, fn %{user: user} ->
      CheckingAccount.create_changeset(%{user_id: user.id, balance: 1_000})
    end)
    |> Repo.transaction()
    |> case do
      {:ok, %{user: user}} ->
        {:ok, user}

      {:error, _failed_operation, failed_value, _changes_so_far} ->
        {:error, failed_value}
    end
  end

  @doc """
  Updates a user.

  ## Examples

      iex> update_user(user, %{field: new_value})
      {:ok, %User{}}

      iex> update_user(user, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_user(%User{} = user, attrs) do
    user
    |> User.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a user.

  ## Examples

      iex> delete_user(user)
      {:ok, %User{}}

      iex> delete_user(user)
      {:error, %Ecto.Changeset{}}

  """
  def delete_user(%User{} = user) do
    Repo.delete(user)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking user changes.

  ## Examples

      iex> change_user(user)
      %Ecto.Changeset{data: %User{}}

  """
  def change_user(%User{} = user, attrs \\ %{}) do
    User.changeset(user, attrs)
  end

  def user_sign_in(email, password) do
    with {:ok, user} <- get_user_by_email(email),
         {:ok, _} <- verify_password(user, password) do
      Guardian.encode_and_sign(user)
    else
      {:error, :user_not_found} ->
        Bcrypt.no_user_verify()
        {:error, :unauthorized}

      _ ->
        {:error, :unauthorized}
    end
  end

  defp get_user_by_email(email) do
    case Repo.get_by(User, email: email) do
      nil ->
        {:error, :user_not_found}

      user ->
        {:ok, user}
    end
  end

  defp verify_password(%User{} = user, password) do
    case Bcrypt.check_pass(user, password) do
      {:ok, user} -> {:ok, user}
      _ -> :error
    end
  end

  @spec transaction(atom(), integer(), Keyword.t()) :: []
  def transaction(action, amount, opts \\ [])

  def transaction(:withdraw, amount, opts) do
    []
  end
end
