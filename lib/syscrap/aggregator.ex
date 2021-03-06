require Syscrap.Helpers, as: H

defmodule Syscrap.Aggregator do
  use Supervisor

  @moduledoc """
    Main aggregation supervisor. It spawns and supervises one
    `Aggregator.Worker` for each `Target` defined on DB.
  """

  def start_link(opts) do
    Supervisor.start_link(__MODULE__, opts, [name: __MODULE__])
  end

  def init(_), do: supervise([], strategy: :one_for_one)

  @doc """
    Populator desired_children function
  """
  def desired_children(_) do
    H.Db.find("targets")
    |> add_worker_names
  end

  @doc """
    Populator child_spec function
  """
  def child_spec(data, _) do
    args = [data: data,
            name: data[:name]]

    supervisor(Syscrap.Aggregator.Worker, [args], [id: args[:name]])
  end

  defp add_worker_names(workers) do
    workers |> Enum.map( fn(t) ->
      name = String.to_atom("Aggregator for #{t.target}")
      Map.put(t, :name, name)
    end )
  end

end
