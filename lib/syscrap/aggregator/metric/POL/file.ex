defmodule Syscrap.Aggregator.Metric.POL.File do
  @behaviour Syscrap.Aggregator.Metric

  def gather_loop(opts) do
    :timer.sleep(1000)
    gather_loop(opts)
  end
end
