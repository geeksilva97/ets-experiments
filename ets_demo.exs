defmodule ETSDemo do
  def demo do
    saved_key = "+5585986050739"
    # options ---> [type, access, named_table]
    table = :ets.new(:cache_chat_customers, [:set, :public, :named_table])

    :ets.insert(
      table,
      {saved_key,
       %{
         name: "Edy Silva",
         address: %{}
       }, 100}
    )

    :ets.insert(
      table,
      {"phone_number1",
       %{
         name: "marcelo",
         address: %{}
       }, 100}
    )

    :ets.insert(
      table,
      {"phone_number2",
       %{
         name: "marcelo",
         address: %{}
       }, 99}
    )

    # spawn(fn ->
    #   IO.puts("I am another process that is about to read the ets table")

    #   [{_key, user_data}] = :ets.lookup(:cache_chat_customers, saved_key)

    #   IO.puts("from spawned process #{inspect(user_data)}")

    #   IO.puts("finishing this process #{inspect(self())}")
    # end)

    # match_result = :ets.match(table, {:"$1", :_})
    # :ets.fun2ms(fn {key, value} -> key end)

    :ets.match(table, :"$1") |> IO.inspect()
    :ets.match(table, {:_, :"$1", 100}) |> IO.inspect()
    # --> has continuation
    :ets.match(table, {:_, :"$1", 100}, 1) |> IO.inspect()

    IO.puts("\n--------\n\n")

    match_head = {:"$1", :"$2", :"$3"}
    # [{operand, operator1, operator2}]
    guards = [{:<, :"$3", 100}]

    # https://www.erlang.org/doc/man/ets#select-2
    :ets.select(table, [{match_head, guards, [:"$_"]}]) |> IO.inspect()
    :ets.select(table, [{match_head, guards, [{{ :"$1", :"$3", :"$1" }}]}]) |> IO.inspect()

  end
end

ETSDemo.demo()
