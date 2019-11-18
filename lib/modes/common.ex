defmodule Sonix.Modes.Common do
  import Sonix.Util, only: [sync_command: 2]

  defmacro __using__(_opts) do
    quote generated: true do
      import Sonix.Util, only: [sync_command: 2, async_command: 2, compact_options: 1]

      defdelegate ping(conn), to: unquote(__MODULE__)
      defdelegate quit(conn), to: unquote(__MODULE__)
    end
  end

  @doc """
  Ping server
  """
  def ping(conn) do
    with({:ok, "PONG"} <- sync_command(conn, type: "PING")) do
      :ok
    else
      error -> error
    end
  end

  @doc """
  Stop connection
  """
  def quit(conn) do
    with({:ok, "ENDED " <> _} <- sync_command(conn, type: "QUIT")) do
      Sonix.Tcp.close(conn)
      :ok
    else
      error -> error
    end
  end
end
