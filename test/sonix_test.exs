defmodule SonixTest do
  use ExUnit.Case, async: true
  # doctest Sonix
  require Logger
  alias Sonix.Tcp

  @pwd "SecretPassword"

  setup do
    on_exit(&flush/0)
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

  test "SEARCH LARGE data" do
    conn = start_mode("ingest")

    prefix = "00000000-0000-0000-0000-000000000"
    for i <- 1..100 do
      uuid = prefix <> (i |> to_string() |> String.pad_leading(3, "0"))
      :ok = Sonix.Modes.Ingest.push(conn, "messages", uuid, "Spiderman #{i} is bad movie")
    end
    Sonix.quit(conn)

    conn = start_mode("search")

    {:ok, result} = Sonix.query(conn, "messages", "Spiderman", limit: 100)
    Enum.each result, fn uuid ->
      assert String.length(uuid) === 36
    end

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

  test "custom name of the GenServer" do
    {:ok, _conn} = Sonix.init("localhost", 1491, name: SearchConn)
    {:ok, _conn} = Sonix.start(SearchConn, "search", @pwd)

    assert :ok === Sonix.ping(SearchConn)

    Sonix.quit(SearchConn)
  end

  test "QUIT" do
    conn = start_mode("search")

    assert :ok === Sonix.quit(conn)
    refute Process.alive?(conn)
  end

  test "QUIT when mode not started" do
    {:ok, conn} = Sonix.init()

    assert :ok === Sonix.quit(conn)
    refute Process.alive?(conn)
  end

  test "QUIT when authentication_failed" do
    {:ok, conn} = Sonix.init()
    {:error, _} = Sonix.start(conn, "search", "InvalidPassword")

    assert :ok === Sonix.quit(conn)
    refute Process.alive?(conn)
  end

  defp ingest() do
    conn = start_mode("ingest")

    :ok = Sonix.Modes.Ingest.push(conn, "messages", "obj:1", "Spiderman is bad movie")

    :ok =
      Sonix.Modes.Ingest.push(conn, "messages", "obj:2", "Batman and spiderwoman is good Movie")

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
