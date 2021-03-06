defmodule Stone.Transactions.Ledgers do
  @moduledoc """
  Ledgers Module is used to store the checking accounts ledger state into a Gen Server.

  This module will update its own GenServer state as well as the database state.

  The main struct of this GenServer's state is:
  %{
    Stone.Accounts.CheckingAccount.number: %Stone.Transactions.LedgerState{}
  }

  For every new transaction (`withdrawal` or `transfer`) a new ledger event is created and stored at the database, the database is used
  only as a second source and backup.

  All events are grouped by day having their totals and ledger events per day. This is to make it less data to calculate considering that the minimum range of
  report data is per day.

  """
  use GenServer

  require Logger

  @name CheckingAccountLedgers

  alias Stone.Accounts
  alias Stone.Accounts.CheckingAccount
  alias Stone.Repo
  alias Stone.Transactions.{LedgerEvent, LedgerState, TransactionError}

  def start_link(default \\ %{}) do
    GenServer.start_link(__MODULE__, default, name: @name)
  end

  @doc """
  Sends a call to this Server to make a withdrawal operation on the given account using the given amount.

  This will send a :debit operation to the server
  """
  def withdrawal(amount, %CheckingAccount{} = checking_account, opts \\ []) do
    event_date = Keyword.get(opts, :event_date, DateTime.utc_now())

    ledger = %{
      amount: amount,
      description: "Withdrawal from checking account",
      type: :debit,
      checking_account_id: checking_account.id,
      event_date: event_date,
      number: 0
    }

    case GenServer.call(@name, {:debit, ledger, checking_account}) do
      {:ok, response} ->
        GenServer.cast(@name, {:update_ledger_state, checking_account.number})
        {:ok, response}

      error ->
        error
    end
  end

  @doc """
  Sends a call to this Server to make a transfer operation sending it to the given destination account.

  This will send both :debit (source account) and :credit (destination account) operations.
  """
  def transfer(
        amount,
        %CheckingAccount{} = checking_account,
        %CheckingAccount{} = destination_checking_account,
        opts \\ []
      ) do
    event_date = Keyword.get(opts, :event_date, DateTime.utc_now())

    debit_ledger = %{
      amount: amount,
      description: "Transfered to #{destination_checking_account.number}",
      type: :debit,
      checking_account_id: checking_account.id,
      event_date: event_date,
      number: 0
    }

    credit_ledger = %{
      amount: amount,
      description: "Received from #{checking_account.number}",
      type: :credit,
      checking_account_id: destination_checking_account.id,
      event_date: event_date,
      number: 0
    }

    with {:ok, debit_checking_account} <-
           GenServer.call(@name, {:debit, debit_ledger, checking_account}),
         {:ok, _credit_checking_account} <-
           GenServer.call(@name, {:credit, credit_ledger, destination_checking_account}) do
      GenServer.cast(@name, {:update_ledger_state, checking_account.number})
      GenServer.cast(@name, {:update_ledger_state, destination_checking_account.number})

      {:ok, debit_checking_account}
    else
      error -> error
    end
  end

  @doc """
  Takes the ledgers balance of the given account number.

  `account_number` The account number to take the ledger balance of
  `number_of_ledgers` The number of balances to take, 0 for all
  """
  def take_ledgers_balance(account_number, number_of_ledgers) do
    GenServer.call(@name, {:take_ledgers_balance, account_number, number_of_ledgers})
  end

  @doc """
  Sends a credit operation to add 1_000 funds to the newly created account.
  """
  def initial_credit(%CheckingAccount{} = checking_account, opts \\ []) do
    event_date = Keyword.get(opts, :event_date, DateTime.utc_now())

    ledger_event = %{
      amount: 100_000,
      description: "Initial Credit For Opening Account :)",
      type: :credit,
      checking_account_id: checking_account.id,
      event_date: event_date,
      number: 0
    }

    case GenServer.call(@name, {:credit, ledger_event, checking_account}) do
      {:ok, response} ->
        GenServer.cast(@name, {:update_ledger_state, checking_account.number})

        {:ok, response}

      error ->
        error
    end
  end

  def get_status do
    :sys.get_status(@name)
  end

  @impl true
  def init(_ledgers) do
    Logger.warn("=== Starting Ledger State Cache ===")

    ledgers =
      Accounts.list_checking_accounts()
      |> Enum.reduce(%{}, fn checking_account, ledgers ->
        ledger_state =
          checking_account.ledger_events
          |> group_ledger_events_by_day()
          |> reduce_and_calculate_total_by_day()
          |> update_current_state(%LedgerState{balance: checking_account.balance})

        Map.put(ledgers, checking_account.number, ledger_state)
      end)

    Logger.warn("=== Finished Ledger State Cache ===")

    {:ok, ledgers}
  end

  @impl true
  def handle_call(
        {:credit, ledger_event, %CheckingAccount{} = checking_account},
        _from,
        ledgers
      ) do
    with {:current_state, current_state} <-
           {:current_state,
            Map.get(
              ledgers,
              checking_account.number,
              initial_ledger()
            )},
         resulting_balance <- current_state.balance + ledger_event.amount,
         {:ok, db_ledger_event, _db_checking_account} <-
           save_db_state(ledger_event, checking_account, resulting_balance) do
      resulting_state = %{
        current_state
        | balance: resulting_balance,
          ledger_events: current_state.ledger_events ++ [db_ledger_event]
      }

      reply(
        {:ok, db_ledger_event},
        Map.put(ledgers, checking_account.number, resulting_state)
      )
    else
      {:error, changeset} ->
        reply({:error, changeset}, ledgers)
    end
  end

  @impl true
  def handle_call(
        {:debit, ledger_event, %CheckingAccount{} = checking_account},
        _from,
        ledgers
      ) do
    with {:current_state, current_state} <-
           {:current_state, Map.get(ledgers, checking_account.number)},
         resulting_balance <- current_state.balance - ledger_event.amount,
         {:balance, true, _current_balance} <-
           {:balance, resulting_balance >= 0, current_state.balance},
         {:ok, db_ledger_event, _db_checking_account} <-
           save_db_state(ledger_event, checking_account, resulting_balance) do
      resulting_state = %{
        current_state
        | balance: resulting_balance,
          ledger_events: current_state.ledger_events ++ [db_ledger_event]
      }

      reply(
        {:ok, db_ledger_event},
        Map.put(ledgers, checking_account.number, resulting_state)
      )
    else
      {:current_state, nil} ->
        reply(
          TransactionError.invalid_transaction_account_number(checking_account.number),
          ledgers
        )

      {:balance, false, current_balance} ->
        reply(
          TransactionError.invalid_transaction_negative_balance_result(
            ledger_event.amount,
            current_balance
          ),
          ledgers
        )

      {:error, changeset} ->
        reply({:error, changeset}, ledgers)
    end
  end

  @impl true
  def handle_call({:take_ledgers_balance, account_number, number_of_days}, _from, ledgers) do
    %LedgerState{ledger_balances: ledger_balances} =
      Map.get(ledgers, account_number, %LedgerState{})

    ledger_balances =
      case number_of_days do
        0 ->
          ledger_balances

        number_of_days ->
          date_range =
            Date.range(Date.utc_today(), Date.add(Date.utc_today(), number_of_days * -1))

          Enum.filter(ledger_balances, fn {date, _ledger_balance, _ledger_event} ->
            Enum.member?(date_range, date)
          end)
      end

    reply(ledger_balances, ledgers)
  end

  @doc """
  A call to this cast will update the current ledger state.
  The ledger state has its balance and totals grouped by day where each ledger event of that day is grouped in a list as well.
  """
  @impl true
  def handle_cast({:update_ledger_state, account_number}, ledgers) do
    ledgers =
      Map.update(ledgers, account_number, %LedgerState{}, fn ledger_state = %LedgerState{} ->
        ledger_state.ledger_events
        |> group_ledger_events_by_day()
        |> reduce_and_calculate_total_by_day()
        |> update_current_state(ledger_state)
      end)

    {:noreply, ledgers}
  end

  defp group_ledger_events_by_day(ledger_events) do
    Enum.group_by(ledger_events, &DateTime.to_date(&1.event_date))
    |> Enum.into([])
    |> Enum.sort(fn {d1, _}, {d2, _} ->
      case Date.compare(d1, d2) do
        :gt -> true
        :eq -> true
        :lt -> false
      end
    end)
  end

  _doc = """
  Reduces the given ledger events and add to the following totals:
  `Total of Credits` if there's any event of type :credit
  `Total of Debits` if there's any event of type :debit
  `Total` the total of all transactions both credit and debit
  """

  defp reduce_and_calculate_total_by_day(grouped_data) do
    Enum.map(grouped_data, fn {date, ledger_events} ->
      ledger_balance =
        Enum.reduce(
          ledger_events,
          %{total_credits: 0, total_debits: 0, total: 0},
          fn %LedgerEvent{} = ledger_event,
             %{total_credits: total_credits, total_debits: total_debits, total: total} = balance ->
            balance =
              case ledger_event.type do
                :credit ->
                  %{balance | total_credits: total_credits + ledger_event.amount}

                :debit ->
                  %{balance | total_debits: total_debits + ledger_event.amount}
              end

            %{balance | total: total + ledger_event.amount}
          end
        )

      {date, ledger_balance, ledger_events}
    end)
  end

  _doc = """
  Updates the current ledger state by adding the given ledger balances grouped by day.
  It will always check for the current day at the first position of the list and won't go a full list scan
  """

  defp update_current_state(ledger_balances_by_day, %LedgerState{} = ledger_state) do
    ledger_balances =
      case ledger_state.ledger_balances do
        [] ->
          ledger_balances_by_day

        ledger_balances ->
          Enum.reduce(ledger_balances_by_day, ledger_balances, fn ledger_balance,
                                                                  ledger_balances ->
            [{current_date, current_ledger_balance, current_ledger_events} | _tail] =
              ledger_balances

            {grouped_date, grouped_ledger_balance, grouped_ledger_events} = ledger_balance

            case current_date == grouped_date do
              true ->
                ledger_balances
                |> List.replace_at(
                  0,
                  new_ledger_balance(
                    current_date,
                    current_ledger_balance,
                    grouped_ledger_balance,
                    current_ledger_events,
                    grouped_ledger_events
                  )
                )

              false ->
                [ledger_balance | ledger_balances]
            end
          end)
      end

    %LedgerState{ledger_state | ledger_balances: ledger_balances, ledger_events: []}
  end

  defp new_ledger_balance(
         current_date,
         current_ledger_balance,
         grouped_ledger_balance,
         current_ledger_events,
         grouped_ledger_events
       ) do
    {current_date,
     %{
       total_credits: current_ledger_balance.total_credits + grouped_ledger_balance.total_credits,
       total_debits: current_ledger_balance.total_debits + grouped_ledger_balance.total_debits,
       total: current_ledger_balance.total + grouped_ledger_balance.total
     }, grouped_ledger_events ++ current_ledger_events}
  end

  defp reply(response, state) do
    {:reply, response, state}
  end

  defp initial_ledger do
    %LedgerState{balance: 0, ledger_events: []}
  end

  defp save_db_state(ledger_event, %CheckingAccount{} = checking_account, resulting_balance) do
    Ecto.Multi.new()
    |> Ecto.Multi.insert(:ledger_event, LedgerEvent.changeset(%LedgerEvent{}, ledger_event))
    |> Ecto.Multi.update(
      :checking_account,
      CheckingAccount.update_changeset(checking_account, %{balance: resulting_balance})
    )
    |> Repo.transaction()
    |> case do
      {:ok, %{ledger_event: ledger_event, checking_account: checking_account}} ->
        {:ok, ledger_event, checking_account}

      {:error, _failed_operation, failed_value, _changes_so_far} ->
        {:error, failed_value}
    end
  end
end
