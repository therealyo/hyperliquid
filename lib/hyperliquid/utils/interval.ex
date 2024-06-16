defmodule Hyperliquid.Interval do
  @minute 60_000
  @hour @minute * 60
  @day @hour * 24
  @week @day * 7
  @month @day * 30.44

  def list, do:
    [
      "1m",
      "3m",
      "5m",
      "15m",
      "30m",
      "1h",
      "2h",
      "4h",
      "8h",
      "12h",
      "1d",
      "3d",
      "1w",
      "1M"
    ]

  @doc """
  Converts interval to milliseconds.
  """
  def to_milliseconds(interval) do
    case interval do
      "1m" -> @minute
      "3m" -> @minute * 3
      "5m" -> @minute * 5
      "15m" -> @minute * 15
      "30m" -> @minute * 30
      "1h" -> @hour
      "2h" -> @hour * 2
      "4h" -> @hour * 4
      "8h" -> @hour * 8
      "12h" -> @hour * 12
      "1d" -> @day
      "3d" -> @day * 3
      "1w" -> @week
      "1M" -> @month
      _ -> {:error, "Unsupported interval"}
    end
  end

  @doc """
  Rounds the current time up to the nearest interval period specified in milliseconds.
  """
  def next_start(time, interval) do
    interval_period = to_milliseconds(interval)
    remainder = rem(time, interval_period)

    if remainder == 0 do
      time
    else
      time + (interval_period - remainder)
    end
  end
end