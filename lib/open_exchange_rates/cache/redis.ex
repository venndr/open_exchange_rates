defmodule OpenExchangeRates.Cache.Redis do
  @moduledoc """
  Adapter module for caching with Redis.
  """
  use GenServer

  @doc false
  def start_link(_args) do
    GenServer.start_link(__MODULE__, name: __MODULE__)
  end

  @doc false
  def init() do
    cache_config = Application.get_env(:open_exchange_rates, :cache)
    redis_url = Keyword.fetch!(cache_config, :redis_url)

    {:ok, redis_conn} = Redix.start_link(redis_url, name: __MODULE__)
    {:ok, %{redis_conn: redis_conn}}
  end

  @redis_hash "open_exchange_rates"

  @doc false
  def keys() do
    case Redix.command(OpenExchangeRates.Cache.Redis, ["HKEYS", @redis_hash]) do
      {:ok, keys} -> keys

      {:error, _} = error -> error
    end
  end

  @doc false
  def insert(key, value), do: Redix.command(OpenExchangeRates.Cache.Redis, ["HSET", @redis_hash, key, value])

  @doc false
  def lookup(key) do
    case Redix.command(OpenExchangeRates.Cache.Redis, ["HGET", @redis_hash, key]) do
      {:ok, value} -> value

      {:error, _} = error -> error
    end
  end
end
