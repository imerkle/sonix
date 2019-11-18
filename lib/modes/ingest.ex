defmodule Sonix.Modes.Ingest do
  use Sonix.Modes.Common

  @ok_flag "OK"
  @result_flag "RESULT "

  @default_bucket "default"

  @doc """
  Push search data in the index.

  syntax: `PUSH <collection> <bucket> <object> "<text>" [LANG(<locale>)]?`

  ## Examples

      iex> Sonix.Modes.Ingest.push(conn, "messages", "obj:1", "spiderman is cool"])
      :ok

      iex> Sonix.Modes.Ingest.push(conn, "messages", "default", "obj:1", "spiderman is cool"])
      :ok
  """
  @ingest_type "PUSH"
  @permitted_options [:lang]
  def push(conn, collection, object, term) do
    push(conn, collection, @default_bucket, object, term)
  end

  def push(conn, collection, object, term, opts) when is_list(opts) do
    push(conn, collection, @default_bucket, object, term, opts)
  end

  def push(conn, collection, bucket, object, term, opts \\ []) do
    options =
      [
        type: @ingest_type,
        collection: collection,
        bucket: bucket,
        object: object,
        term: term
      ] ++ Keyword.take(opts, @permitted_options)

    with({:ok, @ok_flag} <- sync_command(conn, options)) do
      :ok
    else
      error -> error
    end
  end

  @doc """
  Pop search data from the index.

  syntax: `POP <collection> <bucket> <object> "<text>"`

  ## Examples

      iex> Sonix.Modes.Ingest.pop(conn, "messages", "obj:1", "spiderman"])
      :ok

      iex> Sonix.Modes.Ingest.pop(conn, "messages", "default", "obj:1", "spiderman"])
      :ok
  """
  @ingest_type "POP"
  def pop(conn, collection, object, term) do
    pop(conn, collection, @default_bucket, object, term)
  end

  def pop(conn, collection, bucket, object, term) do
    options = [
      type: @ingest_type,
      collection: collection,
      bucket: bucket,
      object: object,
      term: term
    ]

    counting_response(conn, options)
  end

  @doc """
  Count indexed search data.

  syntax: `COUNT <collection> [<bucket> [<object>]?]?`

  ## Examples

      iex> Sonix.Modes.Ingest.count(conn, "messages"])
      1

      iex> Sonix.Modes.Ingest.count(conn, "messages", "default"])
      1

      iex> Sonix.Modes.Ingest.count(conn, "messages", "default", "obj:1"])
      :ok
  """
  @ingest_type "count"
  def count(conn, collection, bucket \\ nil, object \\ nil) do
    options =
      compact_options(
        type: @ingest_type,
        collection: collection,
        bucket: bucket,
        object: object
      )

    counting_response(conn, options)
  end

  @doc "Flush a collection"
  def flush(conn, collection) do
    flushc(conn, collection)
  end

  @doc "Flush a bucket"
  def flush(conn, collection, bucket) do
    flushb(conn, collection, bucket)
  end

  @doc "Flush an object"
  def flush(conn, collection, bucket, object) do
    flusho(conn, collection, bucket, object)
  end

  @doc """
  Flush all indexed data from a collection.

  syntax: `FLUSHC <collection>`

  ## Examples

      iex> Sonix.Modes.Ingest.flushc(conn, "messages")
      1
  """
  @ingest_type "FLUSHC"
  def flushc(conn, collection) do
    options = [
      type: @ingest_type,
      collection: collection
    ]

    counting_response(conn, options)
  end

  @doc """
  Flush all indexed data from a bucket in a collection.

  syntax: `FLUSHB <collection> <bucket>`

  ## Examples

      iex> Sonix.Modes.Ingest.flushb(conn, "messages", "default")
      1
  """
  @ingest_type "FLUSHB"
  def flushb(conn, collection, bucket) do
    options = [
      type: @ingest_type,
      collection: collection,
      bucket: bucket
    ]

    counting_response(conn, options)
  end

  @doc """
  Flush all indexed data from an object in a bucket in collection.

  syntax: `FLUSHO <collection> <bucket> <object>`

  ## Examples

      iex> Sonix.Modes.Ingest.flusho(conn, "messages", "default", "obj:1")
      1
  """
  @ingest_type "FLUSHO"
  def flusho(conn, collection, bucket, object) do
    options = [
      type: @ingest_type,
      collection: collection,
      bucket: bucket,
      object: object
    ]

    counting_response(conn, options)
  end

  defp counting_response(conn, options) do
    with({:ok, @result_flag <> count} <- sync_command(conn, options)) do
      {:ok, String.to_integer(count)}
    else
      error -> error
    end
  end
end
