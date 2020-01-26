defmodule SampleProgram do

  def count(n) when n > 0 do
    Process.sleep(1)
    1 + count(n-1)
  end

  def count(n) do 1 end

  def spawn_processes(n) when n > 0 do
    spawn_link(SampleProgram, :sleep, [3000])
    spawn_processes(n-1)
  end

  def spawn_processes(n) do end

  def sleep(n) do
    Process.sleep(n)
  end

end