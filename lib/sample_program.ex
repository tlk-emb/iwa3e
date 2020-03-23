defmodule SampleProgram do

  def make_list_pow(n) when n <= 0 do
    [0]
  end

  def make_list_pow(n) do
    Process.sleep(1)
    make_list_pow(n-1) ++ make_list_pow(n-1)
  end

  def make_list_pow2(n) do
    make_list_pow2_loop(round(:math.pow(2, n)))
  end

  def make_list_pow2_loop(n) when n <= 0 do
    [0]
  end

  def make_list_pow2_loop(n) do
    Process.sleep(1)
    make_list_pow2_loop(n-1) ++ [0]
  end

end