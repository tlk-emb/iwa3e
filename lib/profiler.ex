defmodule Profiler do

  def start_dump(receiver_pid, interval_ms \\ 5000) do
    spawn_monitor(Profiler, :dump_processes_info, [receiver_pid, interval_ms])
  end

  def end_dump(_pid) do
    Process.exit(_pid, :kill)
  end

  def receive_write() do
    receive do
      msg -> File.write("./charts/public/dump.log", msg, [:append])
             receive_write
    end
  end

  def receive_dump() do
    File.rm("./charts/public/dump.log")
    spawn(Profiler, :receive_write, [])
  end

  def dump_processes_info(receiver_pid, interval_ms \\ 5000, _pid \\ nil) do
    Stream.interval(interval_ms)
      |> Stream.flat_map(fn _ -> ["Time: " <> Timex.format!(Timex.now, "{ISO:Extended}") <> "\n"] ++ processes_info(_pid) end)
      |> Stream.map(fn info ->
          if is_bitstring(info) do
            info
          else
            "#{inspect(info[:_pid])}&&#{inspect(info[:initial_call])}&&#{inspect(info[:memory])}&&#{inspect(info[:reductions])}&&#{inspect(info[:stacktrace])}\n"
          end
        end)
      |> Stream.each(fn x -> send receiver_pid, x end)
      |> Stream.run
  end

  def processes_info(_pid \\ nil) do
    if (_pid == nil) do Process.list else [_pid] end
      |> Enum.map(fn x -> [_pid: x, info: :recon.info(x)] end)
      |> Enum.map(fn x ->
        [
          _pid: x[:_pid],
          initial_call: x[:info][:location][:initial_call],
          memory: x[:info][:memory_used][:memory],
          reductions: x[:info][:work][:reductions],
          stacktrace: Enum.at(x[:info][:location][:current_stacktrace], 0)
        ] end)
  end

  def start(_class, func, args, receiver_pid, interval_ms \\ 1000) do
    {id, ref} = spawn_monitor(_class, func, args)

    profiler_pid = spawn(Profiler, :dump_processes_info, [receiver_pid, interval_ms, id])

    receive do
      {:DOWN, ref, process, _pid, reason} ->
        Process.demonitor(ref)
        Profiler.end_dump(profiler_pid)
        IO.write("{#{inspect(_class)}, #{inspect(func)}, #{inspect(args)}} has Ended.")
    end
  end

  def parse(pids) do
    logs = "recon.log"
      |> File.stream!
      |> Stream.map( &(String.trim(&1)))
      |> Enum.to_list
      |> Enum.take(-100)
      |> Enum.filter(fn x -> x != "" end)
      |> Enum.filter(fn x -> !String.contains?(x, "'__info__'") end)
      |> Enum.map(fn x -> extract(x) end)
      |> Enum.filter(fn x -> !Enum.member?(pids, elem(x, 1)) end)
      |> Enum.map(fn x -> spawn(Profiler, :observe, [elem(x, 1)]) end)
    logs
  end

  def extract(text) do
    [time, id, info] = String.split(text, " ")
    [p, i, d] = Regex.scan(~r/[\d]+/, id)
      |> Enum.map(fn x -> Enum.at(x, 0) end)
      |> Enum.map(fn x -> String.to_integer(x) end)
    _pid = :c.pid(p, i, d)

    string = "some_module"
    module = string |> Macro.camelize()
    m = Module.concat([Elixir, module])

    {time, _pid, info}
  end
end