defmodule ElixirProfilerTest do
  use ExUnit.Case
  doctest ElixirProfiler

  test "greets the world" do
    assert ElixirProfiler.hello() == :world
  end
end
