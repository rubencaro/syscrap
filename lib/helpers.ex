alias Keyword, as: K

defmodule Syscrap.Helpers do

  @moduledoc """
    require SSHEx.Helpers, as: H  # the cool way
  """
  @doc """
    Convenience to get environment bits. Avoid all that repetitive
    `Application.get_env( :myapp, :blah, :blah)` noise.
  """
  def env(key, default \\ nil), do: env(Mix.Project.get!.project[:app], key, default)
  def env(app, key, default), do: Application.get_env(app, key, default)

  @doc """
    Spit to output any passed variable, with location information.
  """
  defmacro spit(obj \\ "", inspect_opts \\ []) do
    quote do
      %{file: file, line: line} = __ENV__
      name = Process.info(self)[:registered_name]
      chain = [ :bright, :red, "\n\n#{file}:#{line}",
                :normal, "\n     #{inspect self}", :green," #{name}"]

      msg = inspect(unquote(obj),unquote(inspect_opts))
      if String.length(msg) > 2, do: chain = chain ++ [:red, "\n\n#{msg}"]

      # chain = chain ++ [:yellow, "\n\n#{inspect Process.info(self)}"]

      (chain ++ ["\n\n", :reset]) |> IO.ANSI.format(true) |> IO.puts

      unquote(obj)
    end
  end

  @doc """
    Print to stdout a _TODO_ message, with location information.
  """
  defmacro todo(msg \\ "") do
    quote do
      %{file: file, line: line} = __ENV__
      [ :yellow, "\nTODO: #{file}:#{line} #{unquote(msg)}\n", :reset]
      |> IO.ANSI.format(true)
      |> IO.puts
      :todo
    end
  end

  @doc """
    Apply given defaults to given Keyword. Returns merged Keyword.

    The inverse of `Keyword.merge`, best suited to apply some defaults in a
    chainable way.

    Ex:
      kw = gather_data
        |> transform_data
        |> H.defaults(k1: 1234, k2: 5768)
        |> here_i_need_defaults

    Instead of:
      kw1 = gather_data
        |> transform_data
      kw = [k1: 1234, k2: 5768]
        |> Keyword.merge(kw1)
        |> here_i_need_defaults

  """
  def defaults(args, defs) when is_map(args) and is_map(defs) do
    defs |> Map.merge(args)
  end
  def defaults(args, defs) do
    if not([K.keyword?(args), K.keyword?(defs)] === [true, true]),
      do: raise(ArgumentError, "Both arguments must be Keyword lists.")
    defs |> K.merge(args)
  end

  @doc """
    Wait for given function to return true.
    Optional `msecs` and `step`.
    Be aware that exceptions raised and thrown messages by given `func` will be discarded.
  """
  def wait_for(func, msecs \\ 5_000, step \\ 100) do
    res = try do
      func.()
    rescue
      _ -> nil
    catch
      :exit, _ -> nil
    end

    if res do
      :ok
    else
      if msecs <= 0, do: raise "Timeout!"
      :timer.sleep step
      wait_for func, msecs - step, step
    end
  end

  @doc """
    Gets names for children in given supervisor. Children with no registered
    name are not returned. List is sorted.
  """
  def named_children(supervisor) do
    supervisor
      |> Supervisor.which_children
      |> Enum.map(fn({_,pid,_,_})-> Process.info(pid)[:registered_name] end)
      |> Enum.filter(&(&1))
      |> Enum.sort
  end

  @doc """
    Kill all of given supervisor's children
  """
  def kill_children(supervisor) do
    children = supervisor |> Supervisor.which_children
    for {_,pid,_,_} <- children, do: true = Process.exit(pid, :kill)
    :ok
  end

end
