defmodule Sonix do
  alias Sonix.Tcp

  alias Sonix.Modes.{Common, Search, Ingest}

  @moduledoc """
  Highlevel API
  """

  @doc """
  Initializes Tcp Client Genserver

  ## Examples

  iex> Sonix.init()
  #PID<0.177.0>

  """
  def init(host \\ {127, 0, 0, 1}, port \\ 1491) do
    {host, port} = normalize_options(host, port)

    with(
      {:ok, conn} = Tcp.start_link(host, port, [mode: :binary, packet: :line], 1000),
      {:ok, "CONNECTED " <> _server} <- Tcp.recv(conn)
    ) do
      {:ok, conn}
    else
      error -> error
    end
  end

  defp normalize_options(host, port) when is_binary(host) do
    normalize_options(String.to_charlist(host), port)
  end
  defp normalize_options(host, port) when is_binary(port) do
    normalize_options(host, String.to_integer(port))
  end
  defp normalize_options(host, port) do
    {host, port}
  end

  @doc """
  Start with a mode

  ## Examples

  iex> Sonix.start(conn, "search", "SecretPassword")
  {:ok, #PID<0.177.0>}
  """
  def start(conn, channel, password) do
    with(:ok <- Tcp.send(conn, "START #{channel} #{password}")) do
      started = "STARTED #{channel} protocol(1) buffer(20000)"

      case Tcp.recv(conn) do
        {:ok, ^started} -> {:ok, conn}
        {:ok, error} -> {:error, error}
        error -> error
      end
    else
      error -> error
    end
  end

  # Common mode
  defdelegate ping(conn), to: Common
  defdelegate quit(conn), to: Common

  # Search mode
  defdelegate query(conn, collection, term), to: Search
  defdelegate query(conn, collection, term, opts), to: Search
  defdelegate query(conn, collection, bucket, term, opts), to: Search

  defdelegate suggest(conn, collection, term), to: Search
  defdelegate suggest(conn, collection, term, opts), to: Search
  defdelegate suggest(conn, collection, bucket, term, opts), to: Search

  # Ingest mode
  defdelegate push(conn, collection, object, term), to: Ingest
  defdelegate push(conn, collection, object, term, opts), to: Ingest
  defdelegate push(conn, collection, bucket, object, term, opts), to: Ingest

  defdelegate pop(conn, collection, object, term), to: Ingest
  defdelegate pop(conn, collection, bucket, object, term), to: Ingest

  defdelegate count(conn, collection), to: Ingest
  defdelegate count(conn, collection, bucket), to: Ingest
  defdelegate count(conn, collection, bucket, object), to: Ingest

  defdelegate flush(conn, collection), to: Ingest
  defdelegate flush(conn, collection, bucket), to: Ingest
  defdelegate flush(conn, collection, bucket, object), to: Ingest
end
