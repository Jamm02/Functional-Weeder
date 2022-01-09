defmodule LFTest do
  use ExUnit.Case
  doctest LF

  test "greets the world" do
    assert LF.hello() == :world
  end
end
