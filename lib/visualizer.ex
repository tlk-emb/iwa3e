defmodule Visualizer do

  def start(log_path) do
    # TODO: use file_name
    parsed_log = File.stream!("dump.log")
      |> Enum.map(&String.trim/1)
      |> Enum.map(fn x -> parse(x) end)

    date_times = parsed_log
      |> Enum.filter(fn x -> !is_list(x) end)

    infos = parsed_log
      |> Enum.filter(fn x -> is_list(x) end)

    graph_data = %{}

    pids = infos
      |> Enum.map(fn x -> x[:_pid] end)
      |> Enum.uniq

    initial_calls = infos
      |> Enum.group_by(fn x -> x[:_pid] end)
      |> Enum.map(fn x -> elem(x, 1) end)
      |> Enum.map(fn x -> Enum.at(Enum.map(x, fn y -> y[:initial_call] end), 0) end)

    graph_data = pids
      |> Enum.flat_map(fn x -> ["#{x}": []] end)

    memories = infos
      |> Enum.group_by(fn x -> x[:_pid] end)
      |> Enum.map(fn x -> elem(x, 1) end)
      |> Enum.map(fn x -> Enum.map(Enum.with_index(x), fn y -> [Enum.at(date_times, elem(y, 1)), elem(y, 0)[:memory]] end) end)
      |> Enum.with_index
      |> Enum.map(fn x -> %{"name": Enum.at(initial_calls, elem(x, 1)), "data": elem(x, 0)} end)
#      |> Enum.map(fn x -> Chartkick.line_chart x end)
    encoded = Poison.encode!(memories)
    html = Chartkick.line_chart(encoded, height: "1024px", width: "80%")

    script = "
      <script src=\"https://www.google.com/jsapi\"></script>
      <script src=\"https://cdnjs.cloudflare.com/ajax/libs/chartkick/2.3.0/chartkick.min.js\"></script>
    "
    File.write("index.html", script <> html)

    memories
#    memory_uses = parsed_log
#      |> Enum.map(fn x -> get_memory_uses(x) end)
#      |> Enum.filter(fn x -> x != nil end)
#    visualize(memory_uses)
  end

  def parse(text) do
    if String.starts_with?(text, "Time: ") do
      date_time_string = String.replace(text, "Time: ", "")
      {:ok, date_time} = Timex.parse(date_time_string, "{ISO:Extended}")
      date_time
    else
      info = String.split(text, "&&")
      [
        _pid: Enum.at(info, 0),
        initial_call: Enum.at(info, 1),
        memory: Enum.at(info, 2) |> String.to_integer,
        reductions: Enum.at(info, 3) |> String.to_integer
      ]
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