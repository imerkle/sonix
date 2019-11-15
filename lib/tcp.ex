defmodule Sonix.Tcp do
  @moduledoc """
    TCP Connection Layer for Sonix
  """

  require Logger

  use Connection

  def start_link(host, port, opts, timeout \\ 5000) do
    Connection.start_link(__MODULE__, {host, port, opts, timeout})
  end

  @doc """
  Send any Command to Sonic

  ## Examples

      iex> Sonix.send(conn, "PING")
      :ok
  """

  def send(conn, data), do: Connection.call(conn, {:send, data <> "\n"})

  @doc """
  Recieve response from Sonic

  ## Examples

      iex> Sonix.recv(conn)
      PONG
  """
  def recv(conn, bytes \\ 0, timeout \\ 3000) do
    with({:ok, response} <- Connection.call(conn, {:recv, bytes, timeout})) do
      case String.trim(response) do
        "ERR " <> reason -> {:error, reason}
        response -> {:ok, response}
      end
    else
      error -> error
    end
  end

  def close(conn), do: Connection.call(conn, :close)

  def init({host, port, opts, timeout}) do
    s = %{host: host, port: port, opts: opts, timeout: timeout, sock: nil}
    {:connect, :init, s}
  end

  def connect(
        _,
        %{sock: nil, host: host, port: port, opts: opts, timeout: timeout} = s
      ) do
    case :gen_tcp.connect(host, port, [active: false] ++ opts, timeout) do
      {:ok, sock} ->
        {:ok, %{s | sock: sock}}

      {:error, _} ->
        {:backoff, 1000, s}
    end
  end

  def disconnect(info, %{sock: sock} = s) do
    :ok = :gen_tcp.close(sock)

    case info do
      {:close, from} ->
        Connection.reply(from, :ok)

      {:error, :closed} ->
        Logger.error fn -> "Connection closed" end

      {:error, reason} ->
        reason = :inet.format_error(reason)
        Logger.error fn -> "Connection error: #{inspect reason}" end
    end

    {:connect, :reconnect, %{s | sock: nil}}
  end

  def handle_call(_, _, %{sock: nil} = s) do
    {:reply, {:error, :closed}, s}
  end

  def handle_call({:send, data}, _, %{sock: sock} = s) do
    case :gen_tcp.send(sock, data) do
      :ok ->
        {:reply, :ok, s}

      {:error, _} = error ->
        {:disconnect, error, error, s}
    end
  end

  def handle_call({:recv, bytes, timeout}, _, %{sock: sock} = s) do
    case :gen_tcp.recv(sock, bytes, timeout) do
      {:ok, _} = ok ->
        {:reply, ok, s}

      {:error, :timeout} = error ->
        {:reply, error, s}

      {:error, _} = error ->
        {:disconnect, error, error, s}
    end
  end

  def handle_call(:close, from, s) do
    {:disconnect, {:close, from}, s}
  end
end
