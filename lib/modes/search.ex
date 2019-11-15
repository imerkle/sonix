defmodule Sonix.Modes.Search do
  use Sonix.Modes.Common

  @default_bucket "default"

  @doc """
  Query database

  syntax: `QUERY <collection> <bucket> "<terms>" [LIMIT(<count>)]? [OFFSET(<count>)]? [LANG(<locale>)]?`

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

    conn
    |> async_command(options)
    |> convert_result()
  end

  @doc """
  Auto-completes word

  syntax: `SUGGEST <collection> <bucket> "<word>" [LIMIT(<count>)]?`

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

    conn
    |> async_command(options)
    |> convert_result()
  end

  defp convert_result({:ok, result}) do
    {:ok, String.split(result, " ", trim: true)}
  end
  defp convert_result(error), do: error
end
