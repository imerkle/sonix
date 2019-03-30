defmodule Sonix do
  alias Sonix.Tcp

  @moduledoc """
    Highlevel API
  """

  @doc """
  Initializes Tcp Client Genserver

  ## Examples

      iex> Sonix.init()
      #PID<0.177.0>

  """

  def init(host \\ {127,0,0,1}, port \\ 1491) do
    {:ok, conn} = Tcp.start_link(host, port, [mode: :binary, packet: :line], 1000)
    Tcp.recv(conn)
    conn
  end

  @doc """
  Start with a mode

  ## Examples

      iex> Sonix.start(conn, "search", "SecretPassword")
      :ok
  """

  def start(conn, channel, password) do
    :ok = Tcp.send(conn, "START #{channel} #{password}")
    Tcp.recv(conn)
  end
  

  @doc """
  
  Query/Suggest a term
  
  ## Parameters

    - opts: default values are [type: "QUERY", collection: "", bucket: "default", term: "", limit: 10, offset: 0]

  ## Examples

      iex> Sonix.search(conn, [type: "QUERY", collection: "messages", "term": "spiderman"])
      obj:1
      
      iex> Sonix.suggest(conn, [type: "SUGGEST", collection: "messages", "term": "spider"])
      spiderman
      
  """

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
  

  @doc """
  
  Push a text
  
  ## Parameters

    - opts: default values are [collection: "", bucket: "default", object: "", term: ""]

  ## Examples

      iex> Sonix.push(conn, [collection: "messages", object: "obj:1", "term": "spiderman is cool"])
      :ok
      
  """

  @default_push %{collection: "", bucket: "default", object: "", term: ""}  
  def push(conn, opts \\ []) do
    %{collection: collection, bucket: bucket, object: object, term: term} = Enum.into(opts, @default_push)
    :ok = Tcp.send(conn, "PUSH #{collection} #{bucket} #{object} \"#{term}\" ")
    case Tcp.recv(conn) do
      "OK" -> :ok
      "ERR " <> reason -> {:err, reason}
    end
  end

  @doc """
  
  Pop a text
  
  ## Parameters

    - opts: default values are [collection: "", bucket: "default", object: "", term: ""]

  ## Examples

      iex> Sonix.pop(conn, [collection: "messages", object: "obj:1", "term": "spiderman"])
      1
      
  """

  def pop(conn, opts \\ []) do
    %{collection: collection, bucket: bucket, object: object, term: term} = Enum.into(opts, @default_push)
    :ok = Tcp.send(conn, "POP #{collection} #{bucket} #{object} \"#{term}\" ")
    "RESULT " <> n = Tcp.recv(conn)
    n |> Integer.parse() |> elem(0)
  end
  
  @doc """
  
  Flush a collection, bucket or object
  
  ## Parameters

    - opts: default values are [collection: "", bucket: "", object: ""]

  ## Examples

      iex> Sonix.flush(conn, [collection: "messages"])
      1
      
  """

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

  @doc """
  
  Count items in a collection, bucket or object
  
  ## Parameters

    - opts: default values are [collection: "", bucket: "", object: ""]

  ## Examples

      iex> Sonix.count(conn, [collection: "messages"])
      1
      
  """

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

  @doc """
  
  Close a TCP connection

  ## Examples

      iex> Sonix.quit(conn)
      :ok
  """

  def quit(conn) do
    Tcp.send(conn, "QUIT")
    Tcp.recv(conn)    
  end

end