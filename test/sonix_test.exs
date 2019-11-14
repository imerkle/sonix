defmodule SonixTest do
  use ExUnit.Case, async: true
  # doctest Sonix
  require Logger
  alias Sonix.Tcp

  @pwd "SecretPassword"

  def ingest() do
    conn = Sonix.init()
    Sonix.start(conn, "ingest", @pwd)

    :ok =
      Sonix.push(conn, collection: "messages", object: "obj:1", term: "Spiderman is bad movie")

    :ok =
      Sonix.push(conn,
        collection: "messages",
        object: "obj:2",
        term: "Batman and spiderwoman is good Movie"
      )

    Sonix.quit(conn)
  end

  def flush() do
    conn = Sonix.init()
    Sonix.start(conn, "ingest", @pwd)
    _n = Sonix.flush(conn, collection: "messages")
    # Logger.info("Flushed #{n}")
    Sonix.quit(conn)
  end

  test "PING PONG" do
    conn = Sonix.init()
    Sonix.start(conn, "search", @pwd)

    Tcp.send(conn, "PING")
    y = Tcp.recv(conn)

    Sonix.quit(conn)

    assert y == "PONG"
  end

  test "FLUSH ALL" do
    flush()

    conn = Sonix.init()
    Sonix.start(conn, "ingest", @pwd)
    x = Sonix.count(conn, collection: "messages")

    assert x == 0
    Sonix.quit(conn)
  end

  test "PUSH DATA" do
    ingest()
  end

  test "POP DATA" do
    flush()
    ingest()

    conn = Sonix.init()
    Sonix.start(conn, "ingest", @pwd)
    x = Sonix.pop(conn, collection: "messages", object: "obj:1", term: "spiderman")

    assert x == 1

    x = Sonix.pop(conn, collection: "messages", object: "obj:3", term: "noman")
    assert x == 0

    Sonix.quit(conn)
  end

  test "SEARCH DATA" do
    flush()
    ingest()

    conn = Sonix.init()
    Sonix.start(conn, "search", @pwd)

    x = Sonix.search(conn, type: "QUERY", collection: "messages", term: "movie")
    assert x == ["obj:2", "obj:1"]
    x = Sonix.search(conn, type: "QUERY", collection: "messages", term: "Spiderman")
    assert x == ["obj:1"]

    Sonix.quit(conn)
  end

  test "SEARCH INVALID DATA" do
    flush()
    ingest()

    conn = Sonix.init()
    Sonix.start(conn, "search", @pwd)

    x = Sonix.search(conn, type: "QUERY", collection: "messages", term: "thisdoesnotexists")
    assert x == []

    Sonix.quit(conn)
  end

  test "ERROR HANDLE" do
    conn = Sonix.init()
    Sonix.start(conn, "search", @pwd)

    try do
      :ok = Tcp.send(conn, "CAUSE AN ERROR")
      IO.inspect(Tcp.recv(conn))
    rescue
      # Logger.info("Caught Error")
      RuntimeError -> ""
    end
  end

  """
   Some issues SUGGEST isn't working with recently created data.
    test "SUGGEST DATA" do
      flush()
      ingest()

      conn = Sonix.init()
      Sonix.start(conn, "search", @pwd)

      x = Sonix.search(conn, [type: "SUGGEST", collection: "messages", term: "spi"])
      assert x == ["spiderman", "spiderwoman"]

      Sonix.quit(conn)
    end
  """
end
