defmodule Visualizer do

  def start(log_path) do
    parsed_log = File.stream!("process.log")
      |> Enum.map(&String.trim/1)
      |> Enum.map(fn x -> parse(x) end)

    memory_uses = parsed_log
      |> Enum.map(fn x -> get_memory_uses(x) end)
      |> Enum.filter(fn x -> x != nil end)
    visualize(memory_uses)

    process_time = parsed_log
      |> Enum.map(fn x -> get_process_time(x) end)
      |> Enum.filter(fn x -> x != nil end)

    IO.puts("Process Start")
    IO.puts(Enum.at(process_time, 0))
    if length(process_time) > 1 do
      IO.puts("Process End")
      IO.puts(Enum.at(process_time, 1))
    else
      IO.puts("Process was not ended")
    end
  end

  def parse(text) do
     case String.split(text, " ") do
       ["Start" | tail] -> {:start, tail}
       ["End" | tail] -> {:end, tail}
       ["Memory" | tail] -> {:memory, tail -- ["Used:", "Bytes"]}
     end
  end

  def get_memory_uses(data) do
    case data do
      {:start, _} -> nil
      {:end, _} -> nil
      {:memory, info} -> Enum.at(info, 0)
    end
  end

  def get_process_time(data) do
    case data do
      {:start, info} -> info
      {:end, info} -> info
      {:memory, _} -> nil
    end
  end

  def visualize(memory_uses) do
    xs = 1..length(memory_uses) |> Enum.map(fn x -> x end)

    PlotlyEx.plot([%{type: "scatter", x: xs, y: memory_uses, text: memory_uses}])
      |> PlotlyEx.show
  end

#  [
#    start: ["#PID<0.174.0>", "2020-01-23", "06:16:45.706405Z"],
#    memory: ["5764", "#PID<0.174.0>", "2020-01-23", "06:16:46.716593Z"],
#    memory: ["13668", "#PID<0.174.0>", "2020-01-23", "06:16:47.717152Z"],
#    memory: ["13668", "#PID<0.174.0>", "2020-01-23", "06:16:48.718315Z"],
#    memory: ["21572", "#PID<0.174.0>", "2020-01-23", "06:16:49.719156Z"],
#    memory: ["21572", "#PID<0.174.0>", "2020-01-23", "06:16:50.720384Z"],
#    memory: ["34364", "#PID<0.174.0>", "2020-01-23", "06:16:51.721164Z"],
#    memory: ["34364", "#PID<0.174.0>", "2020-01-23", "06:16:52.722328Z"],
#    memory: ["34364", "#PID<0.174.0>", "2020-01-23", "06:16:53.724357Z"],
#    memory: ["55060", "#PID<0.174.0>", "2020-01-23", "06:16:54.725476Z"],
#    memory: ["55060", "#PID<0.174.0>", "2020-01-23", "06:16:55.726347Z"],
#    memory: ["55060", "#PID<0.174.0>", "2020-01-23", "06:16:56.727124Z"],
#    memory: ["55060", "#PID<0.174.0>", "2020-01-23", "06:16:57.728270Z"],
#    memory: ["55060", "#PID<0.174.0>", "2020-01-23", "06:16:58.729523Z"],
#    memory: ["88548", "#PID<0.174.0>", "2020-01-23", "06:16:59.731186Z"],
#    memory: ["88548", "#PID<0.174.0>", "2020-01-23", "06:17:00.732359Z"],
#    memory: ["88548", "#PID<0.174.0>", "2020-01-23", "06:17:01.733580Z"],
#    memory: ["88548", "#PID<0.174.0>", "2020-01-23", "06:17:02.735234Z"],
#    memory: ["88548", "#PID<0.174.0>", "2020-01-23", "06:17:03.736238Z"],
#    memory: ["88548", "#PID<0.174.0>", "2020-01-23", "06:17:04.737207Z"],
#    end: ["#PID<0.174.0>", "2020-01-23", "06:17:05.734414Z"]
#  ]


end