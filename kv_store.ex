defmodule KVStore do
  def start do
    Process.flag(:trap_exit, true)
    init()
    spawn_link(KVStore, :loop, []) |> Process.register(__MODULE__)
  end

  def set(key, value) do
    payload = {self(), {:set, {key, value}}}

    send(__MODULE__, payload)
  end

  def set_ex(key, value, ex) do
    payload = {self(), {:setex, {key, value, ex}}}

    send(__MODULE__, payload)
  end

  def get(key) do
    payload = {self(), {:get, key}}

    send(__MODULE__, payload)

    receive do
      value -> value
      _ -> nil
    end
  end

  def init() do
    {:ets.new(__MODULE__, [:set, :public, :named_table])}
  end

  defp get_item([]) do
    nil
  end

  defp get_item([{key, value, expiration_time}]) do
    current_datetime_in_sec = :erlang.localtime() |> :calendar.datetime_to_gregorian_seconds()

    IO.puts(
      "Current Time: #{inspect(:erlang.localtime())} // Expiration time: #{inspect(:calendar.gregorian_seconds_to_datetime(expiration_time))} | is expired=#{current_datetime_in_sec > expiration_time}"
    )

    cond do
      current_datetime_in_sec > expiration_time ->
        # TODO: send message to delete key
        nil

      true ->
        value
    end
  end

  def loop() do
    receive do
      {from, {:get, key}} ->
        item = :ets.lookup(__MODULE__, key)
        IO.puts("blah blah ---> #{inspect(item)}")
        send(from, get_item(item))

      {from, {:set, {key, value}}} ->
        :ets.insert(__MODULE__, {key, value, nil})

      {from, {:setex, {key, value, ex}}} ->
        current_date_time = :erlang.localtime()
        current_datetime_in_sec = :calendar.datetime_to_gregorian_seconds(current_date_time)
        IO.puts("Datetime in seconds -- #{current_datetime_in_sec}")
        # :calendar.gregorian_seconds_to_datetime()

        :ets.insert(__MODULE__, {key, value, current_datetime_in_sec + ex})

      _ ->
        IO.puts("Unexpected message")
    end

    loop()
  end
end
