defmodule SonixTest do
  use ExUnit.Case, async: true
  # doctest Sonix
  require Logger
  alias Sonix.Tcp

  @pwd "SecretPassword"

  setup do
    on_exit &flush/0
  end

  test "PING PONG" do
    conn = start_mode("search")

    assert :ok === Sonix.ping(conn)

    Sonix.quit(conn)
  end

  test "FLUSH ALL" do
    conn = start_mode("ingest")

    assert {:ok, 0} === Sonix.count(conn, "messages")

    Sonix.quit(conn)
  end

  test "PUSH DATA" do
    ingest()
  end

  test "POP DATA" do
    ingest()

    conn = start_mode("ingest")

    assert {:ok, 1} === Sonix.pop(conn, "messages", "obj:1", "spiderman")
    assert {:ok, 0} === Sonix.pop(conn, "messages", "obj:3", "noman")

    Sonix.quit(conn)
  end

  test "SEARCH DATA" do
    ingest()

    conn = start_mode("search")

    assert {:ok, ["obj:2", "obj:1"]} === Sonix.query(conn, "messages", "movie")
    assert {:ok, ["obj:1"]} === Sonix.query(conn, "messages", "Spiderman")

    Sonix.quit(conn)
  end

  test "SEARCH INVALID DATA" do
    ingest()

    conn = start_mode("search")

    assert {:ok, []} === Sonix.query(conn, "messages", "thisdoesnotexists")

    Sonix.quit(conn)
  end

  test "ERROR HANDLE" do
    conn = start_mode("search")

    :ok = Tcp.send(conn, "CAUSE AN ERROR")

    assert {:error, _reason} = Tcp.recv(conn)
  end

  test "SUGGEST DATA" do
    ingest()

    conn = start_mode("search")

    control_conn = start_mode("control")
    Sonix.trigger(control_conn, "consolidate")
    Sonix.quit(control_conn)

    {:ok, result} = Sonix.suggest(conn, "messages", "spi")
    assert result === ["spiderman", "spiderwoman"]

    Sonix.quit(conn)
  end

  defp ingest() do
    conn = start_mode("ingest")

    :ok = Sonix.Modes.Ingest.push(conn, "messages", "obj:1", "Spiderman is bad movie")
    :ok = Sonix.Modes.Ingest.push(conn, "messages", "obj:2", "Batman and spiderwoman is good Movie")

    Sonix.quit(conn)
  end

  defp flush() do
    conn = start_mode("ingest")

    {:ok, _count} = Sonix.flush(conn, "messages")

    Sonix.quit(conn)
  end

  defp start_mode(mode) do
    {:ok, conn} = Sonix.init()
    {:ok, conn} = Sonix.start(conn, mode, @pwd)

    conn
  end
end
