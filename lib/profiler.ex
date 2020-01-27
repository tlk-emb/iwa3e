defmodule Profiler do

  @log_path "process.log"

  observed_pids = []

  def start_dump(file_name, interval_ms \\ 1000) do
    spawn_link(Profiler, :dump_processes_info, [file_name, interval_ms])
  end

  def end_dump(_pid) do
    Process.exit(_pid, :normal)
  end

  def dump_processes_info(file_name, interval_ms) do
    Stream.interval(interval_ms)
      |> Stream.flat_map(fn _ -> ["Time: " <> Timex.format!(Timex.local, "{ISO:Extended}") <> "\n"] ++ processes_info end)
      |> Stream.map(fn info ->
          if is_bitstring(info) do
            info
          else
            "#{inspect(info[:_pid])}&&#{inspect(info[:initial_call])}&&#{inspect(info[:memory])}&&#{inspect(info[:reductions])}&&#{inspect(info[:stacktrace])}\n"
          end
        end)
      |> Stream.into(File.stream!(file_name, [:append]))
      |> Stream.run
  end

  def processes_info() do
    Process.list
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

  def receive_info() do
    receive do
      {:io_request, id, ref, data} -> IO.inspect(data)
    end
  end

  def observe(_pid) do
    File.write(@log_path, "Start #{pid_datetime_to_string(_pid)}\n", [:append])

    Process.monitor(_pid)

    IO.puts("Profiler Process ID: " <> inspect(self))
    spawn(Profiler, :monitor_memory_use, [_pid])

    receive do
      {:DOWN, ref, process, _pid, reason} ->
        Process.demonitor(ref)
        IO.inspect(_pid)
        IO.puts("#{pid_datetime_to_string(_pid)} Process Down! reason: #{reason}")
        File.write(@log_path, "End #{pid_datetime_to_string(_pid)}\n", [:append])
      {:io_request, _pid, _, {_}} -> File.write("trace.log", inspect(_pid), [:append])
      {_} ->
        IO.puts("some message")
    end
  end

  def start(_class, func, args) do
    {id, ref} = spawn_monitor(_class, func, args)

    IO.puts("Target Process ID: " <> inspect(id))

    File.write(@log_path, "Start #{pid_datetime_to_string(id)}\n", [:append])

    IO.puts("Profiler Process ID: " <> inspect(self))
    spawn(Profiler, :monitor_memory_use, [id])

    receive do
      {:DOWN, ref, process, _pid, reason} ->
        Process.demonitor(ref)
        IO.inspect(_pid)
        IO.puts("#{pid_datetime_to_string(id)} Process Down! reason: #{reason}")
        File.write(@log_path, "End #{pid_datetime_to_string(id)}\n", [:append])
      {:io_request, _pid, _, {_}} -> File.write("trace.log", inspect(_pid), [:append])
      {_} ->
        IO.puts("some message")
    end
  end

  def monitor_memory_use(id) do
    Stream.interval(1000)
    |> Stream.filter(fn _ -> Process.alive?(id) end)
    |> Stream.map(fn _ -> write_memory_usage(id) end)
    |> Enum.take_while(fn _ -> Process.alive?(id) end)
  end

  def write_memory_usage(id) do
    File.write(@log_path, "Memory Used: #{to_string(:recon.info(id)[:memory_used][:memory])} Bytes #{pid_datetime_to_string(id)}\n", [:append])
  end

  def pid_datetime_to_string(id) do
    inspect(id) <> " " <> to_string(DateTime.utc_now)
  end

end