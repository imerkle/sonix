defmodule Sonix.Modes.Control do
  use Sonix.Modes.Common

  @ok_flag "OK"

  @doc """
  Trigger an action.
  syntax: `TRIGGER [<action>]? [<data>]?`

  ## Examples

      iex> Sonix.Modes.Control.trigger(conn, "consolidate"])
      :ok
  """
  @control_type "TRIGGER"
  def trigger(conn, "consolidate" = action) do
    do_trigger(conn, [action: action])
  end
  def trigger(conn, action, data) when action in ["backup", "restore"] do
    do_trigger(conn, [action: action, data: data])
  end

  defp do_trigger(conn, opts) do
    options = [type: @control_type] ++ opts
    with({:ok, @ok_flag} <- sync_command(conn, options)) do
      :ok
    else
      error -> error
    end
  end
end
