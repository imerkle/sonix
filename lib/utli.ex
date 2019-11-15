defmodule Sonix.Util do
  alias Sonix.Tcp

  @doc """
  Returns a keyword options with non nil values.

  ## Examples

      iex> Sonic.Util.compact_options([collection: "messages", bucket: nil])
      [collection: "messages"]
  """
  def compact_options(options) do
    for {key, value} when not is_nil(value) <- options do
      {key, value}
    end
  end

  @doc """
  Send command to Sonic.
  All avaiable options are in their modes.
  """
  def sync_command(conn, opts) do
    with(
      type when not is_nil(type) <- Keyword.get(opts, :type),
      :ok <- Tcp.send(conn, pack_message(opts)),

      {:ok, response} <- Tcp.recv(conn)
    ) do
      {:ok, response}
    else
      nil -> {:error, :invalid_options}
      error -> error
    end
  end

  @doc """
  Send asynchronous command to Sonic.
  All avaiable options are in their modes.
  """
  def async_command(conn, opts) do
    with(
      type when not is_nil(type) <- Keyword.fetch!(opts, :type),
      :ok <- Tcp.send(conn, pack_message(opts)),

      {:ok, "PENDING " <> marker} <- Tcp.recv(conn),
      {:ok, "EVENT " <> result} <- Tcp.recv(conn)
    ) do
      {:ok, String.trim_leading(result, "#{type} #{marker}")}
    else
      nil -> {:error, :invalid_options}
      reason -> {:error, reason}
    end
  end

  defp pack_message([{:type, type} | options]), do: pack_message(options, type)
  defp pack_message([first | rest], acc), do: pack_message(rest, pack_message(first, acc))
  defp pack_message([], acc), do: acc
  defp pack_message({_key, nil}, acc), do: acc
  defp pack_message({:offset, value}, acc), do: "#{acc} OFFSET(#{value})"
  defp pack_message({:limit, value}, acc), do: "#{acc} LIMIT(#{value})"
  defp pack_message({:lang, value}, acc), do: "#{acc} LANG(#{value})"
  defp pack_message({:term, value}, acc), do: ~s[#{acc} "#{value}"]
  defp pack_message({_key, value}, acc), do: "#{acc} #{value}"
end
