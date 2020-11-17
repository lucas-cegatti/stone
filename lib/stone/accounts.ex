defmodule Stone.Accounts do
  @moduledoc """
  Accounts module used to access all function related to users and checking accounts
  """

  import Ecto.Query, warn: false

  alias Stone.Repo
  alias Ecto.Multi
  alias Stone.Guardian
  alias Stone.Accounts.{User, CheckingAccount}
  alias Stone.Transactions.{Ledgers, LedgerEvent}

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
  def get_user!(id), do: Repo.get!(User, id) |> Repo.preload(:checking_account)

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

  def create_user_with_checking_account(attrs \\ %{}, opts \\ []) do
    Multi.new()
    |> Multi.insert(:user, User.changeset(%User{}, attrs))
    |> Multi.insert(:checking_account, fn %{user: user} ->
      CheckingAccount.create_changeset(%{user_id: user.id})
    end)
    |> Repo.transaction()
    |> case do
      {:ok, %{user: user, checking_account: checking_account}} ->
        Ledgers.initial_credit(checking_account, opts)

        user = Repo.preload(user, checking_account: :ledger_events)

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

  @doc """
  Gets a single checking account by id

  ## Examples

      iex> get_checking_acount_by_id(checking_account_id)
      %Stone.Accounts.CheckingAccount{}
  """
  def get_checking_acount_by_id(checking_account_id) do
    Repo.get(CheckingAccount, checking_account_id) |> Repo.preload(:ledger_events)
  end

  @doc """
  Gets a single checking account by its number

  ## Examples

      iex> get_checking_account_by_number(checking_account_number)
      %Stone.Accounts.CheckingAccount{}

      iex> get_checking_account_by_number("invalid")
      nil
  """
  def get_checking_account_by_number(account_number) do
    Repo.get_by(CheckingAccount, number: account_number)
    |> case do
      nil ->
        nil

      checking_account ->
        checking_account |> Repo.preload(:ledger_events)
    end
  end

  @doc """
  Gets all checking accounts.

  ## Examples

      iex> list_checking_accounts()
      [%Stone.Accounts.CheckingAccount{}]
  """
  def list_checking_accounts() do
    ledger_events_query = from(le in LedgerEvent, order_by: [desc: le.event_date])

    from(ca in CheckingAccount, preload: [:user, ledger_events: ^ledger_events_query])
    |> Repo.all()
  end
end
