defmodule Stone.Transactions.Ledgers do
  use GenServer

  @name CheckingAccountLedgers

  alias Stone.Repo
  alias Stone.Accounts.CheckingAccount
  alias Stone.Transactions.{LedgerEvent, TransactionError}

  def start_link(default \\ %{}) do
    GenServer.start_link(__MODULE__, default, name: @name)
  end

  def withdrawal(amount, %CheckingAccount{} = checking_account) do
    ledger = %{
      amount: amount,
      description: "Withdrawal from checking account",
      type: :debit,
      checking_account_id: checking_account.id,
      event_date: DateTime.utc_now(),
      number: 0
    }

    GenServer.call(@name, {:debit, ledger, checking_account})
  end

  def transfer(
        amount,
        %CheckingAccount{} = checking_account,
        %CheckingAccount{} = destination_checking_account
      ) do
    debit_ledger = %{
      amount: amount,
      description: "Transfered to #{destination_checking_account.number}",
      type: :debit,
      checking_account_id: checking_account.id,
      event_date: DateTime.utc_now(),
      number: 0
    }

    credit_ledger = %{
      amount: amount,
      description: "Received from #{checking_account.number}",
      type: :credit,
      checking_account_id: destination_checking_account.id,
      event_date: DateTime.utc_now(),
      number: 0
    }

    GenServer.call(@name, {:debit, debit_ledger, checking_account})
    GenServer.call(@name, {:credit, credit_ledger, destination_checking_account})
  end

  def initial_credit(%CheckingAccount{} = checking_account) do
    ledger_event = %{
      amount: 100000,
      description: "Initial Credit For Opening Account :)",
      type: :credit,
      checking_account_id: checking_account.id,
      event_date: DateTime.utc_now(),
      number: 0
    }

    GenServer.call(@name, {:credit, ledger_event, checking_account})
  end

  @impl true
  def init(ledgers) do
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
         {:ok, db_ledger_event, db_checking_account} <-
           save_db_state(ledger_event, checking_account, resulting_balance) do
      resulting_state = %{
        current_state
        | balance: resulting_balance,
          ledger_events: current_state.ledger_events ++ [db_ledger_event]
      }

      reply(
        {:ok, db_checking_account},
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
         {:ok, db_ledger_event, db_checking_account} <-
           save_db_state(ledger_event, checking_account, resulting_balance) do
      resulting_state = %{
        current_state
        | balance: resulting_balance,
          ledger_events: current_state.ledger_events ++ [db_ledger_event]
      }

      reply(
        {:ok, db_checking_account},
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
        {:error, changeset}
    end
  end

  defp reply(response, state) do
    {:reply, response, state}
  end

  defp initial_ledger() do
    %{balance: 0, ledger_events: []}
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
