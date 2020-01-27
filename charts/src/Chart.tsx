import React from "react";
import { Line } from "react-chartjs-2";
import { ChartOptions } from "chart.js";
import {
  TextField,
  Button,
  Slider,
  makeStyles,
  Typography
} from "@material-ui/core";
import "./Chart.css";
import { isArray } from "util";

type Point = {
  x: number;
  y: number;
};

type Process = {
  pid: string;
  initial_call: string;
  memory: number;
  reductions: number;
  time: number;
  stacktrace: string;
};

type ChartData = {
  pid: string;
  initial_call: string;
  points: Point[];
  stacktraces: string[];
};

const makeData = (pointsList: ChartData[]) => {
  var randomColor = () => {
    return "#" + Math.floor(Math.random() * 16777215).toString(16);
  };
  const datasets = pointsList.map((points_info: ChartData) => {
    return {
      label: points_info.pid + points_info.initial_call,
      fill: false,
      data: points_info.points,
      borderColor: randomColor(),
      hidden: false
    };
  });
  if (!datasets) {
    return {
      datasets: {}
    };
  }
  return {
    datasets: datasets
  };
};

const changeDataHidden = (data: any, isHidden: boolean) => {
  return {
    datasets: data.datasets.map((dataset: any) => {
      return {
        ...dataset,
        hidden: isHidden
      };
    }),
    labels: data.labels
  };
};

const groupBy = <T extends { [key: string]: any }>(
  objects: T[],
  key: keyof T
): { [key: string]: T[] } =>
  objects.reduce((map, obj) => {
    map[obj[key]] = map[obj[key]] || [];
    map[obj[key]].push(obj);
    return map;
  }, {} as { [key: string]: T[] });

const readLog = async (): Promise<string> => {
  const logFile = await fetch("/dump.log");
  return logFile.text();
};

const getChartData = async () => {
  const log = await readLog();
  const logs = log.split("\n");
  const times: number[] = logs
    .filter((text: string) => {
      return text.startsWith("Time: ");
    })
    .map((time: string) => {
      const trimed_time = time.replace("Time: ", "");
      return Date.parse(trimed_time);
    });

  let count = -1;
  logs
    .filter(text => {
      return text !== "";
    })
    .forEach((text, index) => {
      if (text.startsWith("Time: ")) {
        count += 1;
      } else {
        logs[index] += "&&" + count;
      }
    });

  const memoriesTmp = logs
    .filter((text: string) => {
      return !(text.startsWith("Time: ") || text === "");
    })
    .map((text: string) => {
      const info = text.split("&&");
      return {
        pid: info[0],
        initial_call: info[1],
        memory: parseInt(info[2]),
        reductions: parseInt(info[3]),
        stacktrace: info[4],
        time: parseInt(info[5])
      };
    })
    .filter((info: Process) => {
      return info.initial_call !== "{:proc_lib, :init_p, 5}";
    });

  let pointsList: ChartData[] = [];

  const memories = groupBy(memoriesTmp, "pid");
  for (const key in memories) {
    memories[key].forEach((value, i, _) => {
      value.time = times[value.time];
    });
    pointsList.push({
      pid: key,
      initial_call: memories[key][0].initial_call,
      points: memories[key].map(value => {
        return { x: value.time, y: value.memory };
      }),
      stacktraces: memories[key].map(value => {
        return value.stacktrace;
      })
    });
  }

  return { pointsList, times };
};

const Chart: React.FC = () => {
  const [_data, setData] = React.useState({});
  const [filteredPointsList, setFilterdPointsList] = React.useState(
    [] as ChartData[]
  );
  const [pointsList, setPointsList] = React.useState([] as ChartData[]);
  const [filterText, setFilterText] = React.useState("");
  const [shouldRedraw, setShouldRedraw] = React.useState(false);
  const [isAllHidden, setAllHidden] = React.useState(false);
  const [filterTimes, setFilterTimes] = React.useState([0, 100]);
  const [minMax, setFitlerMinMax] = React.useState([0, 100]);

  React.useEffect(() => {
    const f = async () => {
      const chartData = await getChartData();
      setPointsList(chartData.pointsList);
      setFilterdPointsList(chartData.pointsList);
      setData(makeData(chartData.pointsList));
      setFilterTimes([chartData.times[0], chartData.times.slice(-1)[0]]);
      setFitlerMinMax([chartData.times[0], chartData.times.slice(-1)[0]]);
    };
    f();
  }, []);

  const options: ChartOptions = {
    scales: {
      xAxes: [
        {
          type: "time"
        }
      ]
    },
    tooltips: {
      callbacks: {
        afterLabel: (item, data) => {
          if (item.datasetIndex === undefined || item.index === undefined) {
            return "";
          }
          const points = filteredPointsList[item.datasetIndex];
          if (!points.stacktraces) {
            return "";
          }

          return (
            "stacktrace: " +
            points.stacktraces[item.index] +
            "\nプロセス存在期間: " +
            (points.points.slice(-1)[0].x - points.points[0].x) +
            "ms"
          );
        }
      }
    }
  };

  const refresh = () => {
    setShouldRedraw(true);
    const filteredPointsList = pointsList
      .filter((points: ChartData) => {
        return (
          points.initial_call.includes(filterText) ||
          points.pid.includes(filterText)
        );
      })
      .map(points => {
        return {
          ...points,
          points: points.points.filter(point => {
            return point.x > filterTimes[0] && point.x < filterTimes[1];
          })
        };
      });

    setFilterdPointsList(filteredPointsList);
    setData(makeData(filteredPointsList));
  };

  const filter = (event: React.FormEvent<HTMLFormElement>) => {
    event.preventDefault();

    refresh();
  };

  const onChangeFilterText = (text: string) => {
    setShouldRedraw(false);
    setFilterText(text);
  };

  const onClickHiddenButton = () => {
    const toggledData = changeDataHidden(_data, !isAllHidden);
    setData(toggledData);
    setAllHidden(!isAllHidden);
  };

  const onChangeFilterTimes = (value: number[] | number) => {
    setShouldRedraw(false);
    if (isArray(value)) {
      setFilterTimes(value);
    }
  };

  const updateFilterTimes = () => {
    refresh();
  };

  return (
    <div className="chart">
      <h2>Chart</h2>
      <div className="menu">
        <form onSubmit={event => filter(event)}>
          <TextField
            onChange={text => onChangeFilterText(text.target.value)}
            placeholder="PID or Initial Call"
          ></TextField>
        </form>
        <Button
          variant="contained"
          color="primary"
          onClick={() => onClickHiddenButton()}
        >
          {isAllHidden ? "全て表示する" : "全て非表示にする"}
        </Button>
      </div>
      <Line data={_data} options={options} redraw={shouldRedraw} />
      <Slider
        className="slider"
        value={filterTimes}
        onChange={(_, newValue) => onChangeFilterTimes(newValue)}
        onChangeCommitted={() => updateFilterTimes()}
        aria-labelledby="range-slider"
        min={minMax[0]}
        max={minMax[1]}
      />
      <Typography>{`${new Date(
        filterTimes[0]
      ).toLocaleTimeString()} - ${new Date(
        filterTimes[1]
      ).toLocaleTimeString()}`}</Typography>
    </div>
  );
};

export default Chart;
