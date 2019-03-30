defmodule Sonix do
  alias Sonix.Tcp

  def init(host \\ {127,0,0,1}, port \\ 1491) do
    {:ok, conn} = Tcp.start_link(host, port, [mode: :binary, packet: :line], 1000)
    Tcp.recv(conn)
    conn
  end
  def start(conn, channel, password) do
    :ok = Tcp.send(conn, "START #{channel} #{password}")
    Tcp.recv(conn)
  end
  
  @default_search %{type: "QUERY", collection: "", bucket: "default", term: "", limit: 10, offset: 0}  
  def search(conn, opts \\ []) do
    %{type: type, collection: collection, bucket: bucket, term: term, limit: limit, offset: offset} = Enum.into(opts, @default_search)
    offset_str = if type == "QUERY", do: "OFFSET(#{offset})" ,else: ""
    :ok = Tcp.send(conn, "#{type} #{collection} #{bucket} \"#{term}\" LIMIT(#{limit}) #{offset_str}")
    p = Tcp.recv(conn)
    "PENDING " <> pending_id =  p
    x = Tcp.recv(conn)
    "EVENT " <> y = x
    y |> String.replace("#{type} #{pending_id} ", "") |> String.split(" ") |> Enum.filter(& &1 != "")
  end
  
  @default_push %{collection: "", bucket: "default", object: "", term: ""}  
  def push(conn, opts \\ []) do
    %{collection: collection, bucket: bucket, object: object, term: term} = Enum.into(opts, @default_push)
    :ok = Tcp.send(conn, "PUSH #{collection} #{bucket} #{object} \"#{term}\" ")
    case Tcp.recv(conn) do
      "OK" -> :ok
      "ERR " <> reason -> {:err, reason}
    end
  end

  def pop(conn, opts \\ []) do
    %{collection: collection, bucket: bucket, object: object, term: term} = Enum.into(opts, @default_push)
    :ok = Tcp.send(conn, "POP #{collection} #{bucket} #{object} \"#{term}\" ")
    "RESULT " <> n = Tcp.recv(conn)
    n |> Integer.parse() |> elem(0)
  end
  
  @default_flush %{collection: "", bucket: "", object: ""}  
  def flush(conn, opts \\ []) do
    %{collection: collection, bucket: bucket, object: object} = Enum.into(opts, @default_flush)

    cmd = cond do
      object != "" -> "FLUSHO #{collection} #{bucket} #{object}"
      bucket != "" -> "FLUSHB #{collection} #{bucket}"
      collection != "" -> "FLUSHC #{collection}"
    end

    :ok = Tcp.send(conn, cmd)
    "RESULT " <> n = Tcp.recv(conn)
    n |> Integer.parse() |> elem(0)
  end

  def count(conn, opts \\ []) do
    %{collection: collection, bucket: bucket, object: object} = Enum.into(opts, @default_flush)

    cmd = cond do
      object != "" -> "COUNT #{collection} #{bucket} #{object}"
      bucket != "" -> "COUNT #{collection} #{bucket}"
      collection != "" -> "COUNT #{collection}"
    end

    :ok = Tcp.send(conn, cmd)
    "RESULT " <> n = Tcp.recv(conn)
    n |> Integer.parse() |> elem(0)
  end

  def quit(conn) do
    Tcp.send(conn, "QUIT")
    Tcp.recv(conn)    
  end

end