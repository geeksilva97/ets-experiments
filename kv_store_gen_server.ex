defmodule KeyExpirationListener do
  use GenServer

  def start(ets_table) do
    GenServer.start_link(__MODULE__, ets_table, name: __MODULE__)

    Process.send_after(__MODULE__, :process_keys, 1000)
  end

  def listen(key) do
    GenServer.cast(__MODULE__, {:listen, key})
  end

  def unlisten(key) do
    GenServer.cast(__MODULE__, {:unlisten, key})
  end

  defp key_expired?(ets_object) do
  end

  @impl true
  def init(ets_table) do
    {:ok, %{"ets_table" => ets_table, "keys" => []}}
  end

  @impl true
  def handle_info(message, state = %{"keys" => keys, "ets_table" => ets_table}) do
    current_datetime_in_sec = :erlang.localtime() |> :calendar.datetime_to_gregorian_seconds()

    IO.puts("Listening to keys #{inspect(keys)}")

    new_keys =
      Enum.map(keys, fn key ->
        item = :ets.lookup(ets_table, key)

        case item do
          [] ->
            nil

          [{_, value, expiration_time}] ->
            cond do
              current_datetime_in_sec > expiration_time ->
                IO.puts("Sending pubsub message cause the key #{inspect(key)} is expired already")
                nil

              true ->
                key
            end
        end
      end)

    Process.send_after(__MODULE__, :process_keys, 1000)
    {:noreply, %{state | "keys" => Enum.filter(new_keys, &(!is_nil(&1)))}}
  end

  @impl true
  def handle_cast({:listen, key}, state = %{"keys" => keys}) do
    new_keys_list = [key | keys]

    {:noreply, Map.put(state, "keys", new_keys_list)}
  end

  @impl true
  def handle_call({:keys}, _from, state) do
    keys = state["keys"]

    {:reply, keys, state}
  end
end

defmodule KVStoreGenServer do
  use GenServer

  def start_link() do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init([]) do
    ets_table = :ets.new(__MODULE__, [:set, :public, :named_table])

    KeyExpirationListener.start(ets_table)

    {:ok, ets_table}
  end

  def set(key, value, ex \\ nil) do
    GenServer.cast(__MODULE__, {:set, key, value, [ex: ex]})

    KeyExpirationListener.listen(key)
  end

  def delete(key) do
    GenServer.cast(__MODULE__, {:del, key})

    KeyExpirationListener.unlisten(key)
  end

  def get(key) do
    GenServer.call(__MODULE__, {:get, key})
  end

  def handle_info(message, state) do
    IO.puts("Received message #{inspect(message)}")

    {:noreply, state}
  end

  def build_expiration(nil), do: nil

  def build_expiration(ex) do
    current_datetime_in_sec = :erlang.localtime() |> :calendar.datetime_to_gregorian_seconds()

    IO.puts("Building expiration #{current_datetime_in_sec + ex}")

    current_datetime_in_sec + ex
  end

  def handle_cast(message = {:set, key, value, options}, ets_table) do
    ex = Keyword.get(options, :ex)

    :ets.insert(ets_table, {key, value, build_expiration(ex)})

    IO.puts("Received message || handle_cast #{inspect(message)}")

    {:noreply, ets_table}
  end

  defp get_item(ets_table, key) do
    current_datetime_in_sec = :erlang.localtime() |> :calendar.datetime_to_gregorian_seconds()

    item = :ets.lookup(ets_table, key)

    case item do
      [] ->
        nil

      [{_, value, expiration_time}] ->
        cond do
          current_datetime_in_sec > expiration_time ->
            nil

          true ->
            value
        end
    end
  end

  def handle_call(message = {:get, key}, from, ets_table) do
    item = get_item(ets_table, key)

    IO.puts("Received message || handle_call #{inspect(message)}")

    {:reply, item, ets_table}
  end
end
