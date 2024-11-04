defmodule OpenExchangeRates.Cache.ETS do
  @moduledoc """
  Adapter module for caching with ETS.
  """

  use GenServer

  @doc false
  def start_link(_args) do
    GenServer.start_link(__MODULE__, name: __MODULE__)
  end

  @doc false
  def init() do
    ets = :ets.new(__MODULE__, [:set, :protected, :named_table])

    {:ok, %{ets: ets}}
  end

  @doc false
  def keys(), do: OpenExchangeRates.Cache.ETS |> :ets.match({:"$1", :_}) |> List.flatten()

  @doc false
  def insert(key, value), do: :ets.insert(OpenExchangeRates.Cache.ETS, {key, value})#GenServer.call(__MODULE__, {:insert, key, value})

  @doc false
  def lookup(key) do 
    case :ets.lookup(OpenExchangeRates.Cache.ETS, key) do
      [] -> nil

      [{_, value}] -> value
    end
  end

  # @doc false
  # def handle_call({:insert, key, value}, _caller, %{ets: ets} = state) do
  #   :ets.insert(ets, {key, value})
  # end
end
