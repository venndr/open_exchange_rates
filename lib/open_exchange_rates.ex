defmodule OpenExchangeRates do
  @moduledoc """
  This module contains all the helper methods for converting currencies
  """
  use Application
  require Logger

  @doc false
  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    configuration_status = check_configuration()
    children = [worker(OpenExchangeRates.Cache, [configuration_status])]

    opts = [strategy: :one_for_one, name: OpenExchangeRates.Supervisor]
    Supervisor.start_link(children, opts)
  end

  @doc"""
  Returns a list of all available currencies.

  ## example

      iex> OpenExchangeRates.available_currencies |> Enum.sort() |> Enum.take(10)
      ["AED", "AFN", "ALL", "AMD", "ANG", "AOA", "ARS", "AUD", "AWG", "AZN"]

  """
  @spec available_currencies() :: [String.t]
  def available_currencies, do: OpenExchangeRates.Cache.currencies

  @doc"""
  Returns the age of the cache in seconds

  ## example
      OpenExchangeRates.cache_age
      25341
  """
  @spec cache_age() :: Integer.t
  def cache_age, do: OpenExchangeRates.Cache.cache_age

  @doc"""
  Will convert a price from once currency to another

  ## example

      iex> OpenExchangeRates.convert(Decimal.new("100.00"), :EUR, :GBP)
      {:ok, Decimal.new("84.81186252771618625277161866")}

  """
  @spec convert(Integer.t | Decimal.t, (String.t | Atom.t), (String.t | Atom.t)) :: {:ok, Decimal.t} | {:error, String.t}
  def convert(value, from, to) do
    with \
      {:ok, rate_from} <- OpenExchangeRates.Cache.rate_for_currency(from),
      {:ok, rate_to} <- OpenExchangeRates.Cache.rate_for_currency(to) \
    do
      rate_usd = Decimal.div(value, rate_from)
      converted = Decimal.mult(rate_usd, rate_to)
      {:ok, converted}
    else
      error -> error
    end
  end


  @doc """
  bang method of convert/3
  Will either return the result or raise when there was an error
  ## examples

      iex> OpenExchangeRates.convert!(Decimal.new("100.00"), :EUR, :GBP)
      Decimal.new("84.81186252771618625277161866")

      iex> OpenExchangeRates.convert!(100, :EUR, :GBP)
      Decimal.new("84.81186252771618625277161866")
  """
  @spec convert!(Integer.t | Decimal.t, (String.t | Atom.t), (String.t | Atom.t)) :: {:ok, Decimal.t} | {:error, String.t}
  def convert!(value, from, to) do
    case convert(value, from, to) do
      {:ok, result} -> result
      {:error, message} -> raise(message)
    end
  end

  @doc"""
  Will convert cents from once currency to another

  ## example

      iex> OpenExchangeRates.convert_cents(100, :GBP, :AUD)
      {:ok, 172}

  """
  @spec convert_cents(Integer.t, (String.t | Atom.t), (String.t | Atom.t)) :: {:ok, Integer.t} | {:error, String.t}
  def convert_cents(value, from, to) do
    case convert(divide_by_100(value), from, to) do
      {:ok, result} -> {:ok, result |> Decimal.mult(100) |> Decimal.round() |> Decimal.to_integer()}
      error -> error
    end
  end

  @doc """
  bang method of convert_cents/3
  Will either return the result or raise when there was an error
  ## example

      iex> OpenExchangeRates.convert_cents!(100, :GBP, :AUD)
      172
  """
  @spec convert_cents!(Integer.t, (String.t | Atom.t), (String.t | Atom.t)) :: {:ok, Integer.t} | {:error, String.t}
  def convert_cents!(value, from, to) when is_integer(value) do
    case convert_cents(value, from, to) do
      {:ok, result} -> result
      {:error, message} -> raise(message)
    end
  end

  @doc"""
  Converts cents and returns a properly formatted string for the given currency.

  # Examples

      iex> OpenExchangeRates.convert_cents_and_format(1234567, :EUR, :CAD)
      {:ok, "$18,026.07"}

      iex> OpenExchangeRates.convert_cents_and_format(1234567, :EUR, :USD)
      {:ok, "$13,687"}

      iex> OpenExchangeRates.convert_cents_and_format(1234567, :USD, :EUR)
      {:ok, "€11.135,79"}

      iex> OpenExchangeRates.convert_cents_and_format(1234567, :EUR, :NOK)
      {:ok, "116.495,78kr"}
  """
  @spec convert_cents_and_format(Integer.t, (Atom.t | String.t), (Atom.t | String.t)) :: String.t
  def convert_cents_and_format(value, from, to) do
    case convert_cents(value, from, to) do
      {:ok, result} -> {:ok, CurrencyFormatter.format(result, to)}
      error -> error
    end
  end

  @doc """
  Bang version of convert_cents_and_format/3
  Will either return the result or raise when there was an error

  #example

      iex> OpenExchangeRates.convert_cents_and_format!(1234567, :EUR, :USD)
      "$13,687"
  """
  @spec convert_cents_and_format!(Integer.t, (Atom.t | String.t), (Atom.t | String.t)) :: String.t
  def convert_cents_and_format!(value, from, to) when is_integer(value) do
    case convert_cents_and_format(value, from, to) do
      {:ok, result} -> result
      {:error, message} -> raise(message)
    end
  end

  @doc"""
  Converts a price and returns a properly formatted string for the given currency.

  # Examples

      iex> OpenExchangeRates.convert_and_format(1234, :EUR, :AUD)
      {:ok, "$1,795.10"}
  """
  @spec convert_and_format((Integer.t | Decimal.t), (Atom.t | String.t), (Atom.t | String.t)) :: String.t
  def convert_and_format(value, from, to), do: convert_cents_and_format(Decimal.mult(value, 100), from, to)


  @doc """
  Bang version of convert_and_format/3
  Will either return the result or raise when there was an error

  #example

      iex> OpenExchangeRates.convert_and_format!(1234567, :EUR, :USD)
      "$1,368,699.56"
  """
  @spec convert_and_format!((Integer.t | Decimal.t), (Atom.t | String.t), (Atom.t | String.t)) :: String.t
  def convert_and_format!(value, from, to) when is_integer(value) do
    case convert_and_format(value, from, to) do
      {:ok, result} -> result
      {:error, message} -> raise(message)
    end
  end

  @doc """
  Get the conversion rate for a between two currencies"

  ## Example

      iex> OpenExchangeRates.conversion_rate(:EUR, :GBP)
      {:ok, Decimal.new("0.8481186252771618625277161866")}

  """
  @spec conversion_rate((String.t| Atom.t), (String.t| Atom.t)) :: {:ok, Decimal.t} | {:error, String.t}
  def conversion_rate(from, to) when is_binary(from) and is_binary(to), do: conversion_rate(String.to_atom(from), String.to_atom(to))
  def conversion_rate(from, to), do: convert(Decimal.new("1"), from, to)

  defp divide_by_100(int) when is_integer(int) and int >= 0,
    do: Decimal.new(1, int, -2)

  defp divide_by_100(int) when is_integer(int) and int >= 0,
    do: Decimal.new(-1, abs(int), -2)

  defp divide_by_100(%Decimal{} = dec), do: Decimal.div(dec, 100)

  defp check_configuration do
    cond do
      Application.get_env(:open_exchange_rates, :auto_update) == false -> :disable_updater
      Application.get_env(:open_exchange_rates, :app_id) == nil -> config_error_message(); :missing_key
      true -> :ok
    end
  end

  defp config_error_message do
    Logger.warn ~s[
OpenExchangeRates :

No App ID provided.

Please check if your config.exs contains the following :
  config :open_exchange_rates,
    app_id: "MY_OPENEXCHANGE_RATES_ORG_API_KEY",
    cache_time_in_minutes: 1440,
    cache_file: File.cwd! <> "/priv/exchange_rate_cache.json",
    auto_update: true

If you need an api key please sign up at https://openexchangerates.org/signup

This module will continue to function but will use (outdated) cached exchange rates data...
    ]
  end
end
