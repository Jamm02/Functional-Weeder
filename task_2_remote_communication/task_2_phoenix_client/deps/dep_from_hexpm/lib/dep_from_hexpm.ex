defmodule DepFromHexpm do
  use Application

  def start(_type, _args) do
    Supervisor.start_link([
      {Task, fn -> IO.puts("Remember to keep good posture and stay hydrated!") end}
    ], strategy: :one_for_one)
  end
end