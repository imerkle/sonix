defmodule Sonix.Modes.Search do
  alias Sonix.Tcp

  @default_bucket "default"

  @doc """
  Query a term

  ## Examples

      iex> Sonix.Modes.Search.query(conn, "messages", "spiderman")
      ["obj:1"]

      iex> Sonix.Modes.Search.query(conn, "messages", "default", "spiderman", limit: 1)
      ["obj:1"]
  """
  @search_type "QUERY"
  @permitted_options [:limit, :offset, :lang]
  def query(conn, collection, term) do
    query(conn, collection, @default_bucket, term)
  end
  def query(conn, collection, term, opts) when is_list(opts) do
    query(conn, collection, @default_bucket, term, opts)
  end
  def query(conn, collection, bucket, term, opts \\ [limit: 10, offset: 0]) do
    options = [
      type: @search_type,
      collection: collection,
      bucket: bucket,
      term: term
    ] ++ Keyword.take(opts, @permitted_options)

    command(conn, options)
  end

  @doc """
  Suggest a term

  ## Examples

      iex> Sonix.Modes.Search.suggest(conn, "messages", "spiderman")
      ["spiderman"]

      iex> Sonix.Modes.Search.suggest(conn, "messages", "default", "spiderman", limit: 1)
      ["spiderman"]
  """
  @search_type "SUGGEST"
  @permitted_options [:limit]
  def suggest(conn, collection, term) do
    suggest(conn, collection, @default_bucket, term)
  end
  def suggest(conn, collection, term, opts) when is_list(opts) do
    suggest(conn, collection, @default_bucket, term, opts)
  end
  def suggest(conn, collection, bucket, term, opts \\ [limit: 10]) do
    options = [
      type: @search_type,
      collection: collection,
      bucket: bucket,
      term: term
    ] ++ Keyword.take(opts, @permitted_options)

    command(conn, options)
  end

  defp command(conn, opts) do
    with(
      type when not is_nil(type) <- Keyword.fetch!(opts, :type),
      :ok <- Tcp.send(conn, pack_message(opts)),

      "PENDING " <> pending_id <- Tcp.recv(conn),
      "EVENT " <> result <- Tcp.recv(conn)
    ) do
      result
      |> String.trim_leading("#{type} #{pending_id}")
      |> String.split(" ", trim: true)
    else
      nil -> {:error, :invalid_options}
      reason -> {:error, reason}
    end
  end

  defp pack_message(options, acc \\ "")
  defp pack_message([first | rest], acc) do
    pack_message(rest, pack_message(first, acc))
  end
  defp pack_message([], acc), do: acc
  defp pack_message({_key, nil}, acc), do: acc
  defp pack_message({:offset, value}, acc), do: "#{acc} OFFSET(#{value})"
  defp pack_message({:limit, value}, acc), do: "#{acc} LIMIT(#{value})"
  defp pack_message({:lang, value}, acc), do: "#{acc} LANG(#{value})"
  defp pack_message({:term, value}, acc), do: ~s[#{acc} "#{value}"]
  defp pack_message({:type, value}, _acc), do: value
  defp pack_message({_key, value}, acc), do: "#{acc} #{value}"
end
