defmodule Hyperliquid.Manager do
  use GenServer

  alias Hyperliquid.Cache
  alias Hyperliquid.Api.Subscription
  alias Hyperliquid.Streamer.{Supervisor, Stream}

  @workers :worker_registry
  @users :user_registry

  @max_ws_conns 100
  @max_ws_user_conns 10
  @max_ws_subscriptions 1_000

  def start_link(_) do
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def init(:ok) do
    Cache.init()
    Supervisor.start_stream([%{type: "allMids"}])
    {:ok, %{}}
  end

  # def subscribed?(sub, registry), do: Enum.member?(get_active_subs(registry) , sub)

  def get_subbed_users, do: Registry.select(@users, [{{:"$1", :_, :_}, [], [:"$1"]}])

  def get_active_subs, do:
    @workers
    |> Registry.select([{{:_, :_, :"$3"}, [], [:"$3"]}])
    |> Enum.flat_map(& &1.subs)
    |> Enum.filter(&!Map.has_key?(&1, :user))

  def get_active_non_user_subs, do: get_active_subs() |> Enum.filter(&!Map.has_key?(&1, :user))

  def get_worker_pids, do: Registry.select(@workers, [{{:_, :"$2", :_}, [], [:"$2"]}])

  def get_worker_ids, do: get_worker_pids() |> Enum.flat_map(&Registry.keys(@workers, &1))

  def get_workers, do:
    Supervisor
    |> DynamicSupervisor.which_children()
    |> Enum.map(&elem(&1, 1))

  def maybe_start_stream(sub) when is_map(sub) do
    subbed? = get_active_non_user_subs() |> Enum.member?(sub)

    cond do
      subbed? -> IO.inspect("already subbed to this topic")
      true    -> Supervisor.start_stream([sub])
    end
  end

  # def maybe_start_stream(address) do
  #   subbed = get_subbed_users() |> Enum.member?(address)
  #   pid = find_userless_pids() |> Enum.at(0)
  #   worker_count = get_worker_count()
  #   IO.inspect({subbed, pid, worker_count, find_userless_pids()})
  #   # TODO: may need to async await task
  #   cond do
  #     subbed -> IO.inspect("already subbed to this address")
  #     worker_count < @max_ws_clients -> async_auto_start_user(address)
  #     !is_nil(pid) -> async_auto_start_user(pid, address)
  #     true -> throw("max ws conns reached")
  #   end
  # end

  # defp async_auto_start_user(address) do
  #   task = Task.async(fn -> auto_start_user(address) end)
  #   Task.await(task)
  # end

  # def auto_start_user(address) do
  #   address
  #   |> Subscription.make_user_subs()
  #   |> Supervisor.start_stream()
  # end

  def auto_start_user(address, coin \\ nil) do
    address = String.downcase(address)

    get_subbed_users()
    |> Enum.map(&String.downcase(&1))
    |> Enum.member?(address)
    |> case do
      true -> IO.inspect("already subbed to user")
      _    -> Subscription.make_user_subs(address, coin) |> Supervisor.start_stream()
    end
  end

  def unsubscribe_all(pid) when is_pid(pid) do
    id = Registry.keys(@workers, pid) |> Enum.at(0)

    case id do
      nil -> IO.inspect("not a worker pid")
      _   -> Registry.values(@workers, id, pid) |> Enum.at(0)
    end
    |> Map.get(:subs)
    |> Enum.map(&Stream.unsubscribe(pid, &1))
  end

  def unsubscribe_all(id) when is_binary(id) do
    [{pid, %{subs: subs}}] = Registry.lookup(@workers, id)

    Enum.map(subs, &Stream.unsubscribe(pid, &1))
  end

  # def unsubscribe_all do
  #   @registry
  #   |> Registry.select([{{:"$1", :"$2", :"$3"}, [], [:"$2"]}])
  #   |> Enum.uniq()
  #   |> Enum.flat_map(&Registry.keys(@registry, &1))
  #   |> Enum.flat_map(&Registry.lookup(@registry, &1))
  #   |> Enum.map(fn {pid, sub} ->
  #     Stream.unsubscribe(pid, sub)
  #   end)
  # end

  # # def terminate_innactive do
  # #   WebSockex.send_frame(pid, {:close, %{}})
  # # end

  # def unsubscribe_topic(address, topic_key) do
  #   [{pid, topic}] = Registry.lookup(@registry, {address, topic_key})
  #   Stream.unsubscribe(pid, topic)
  # end
end
