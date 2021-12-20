defmodule CLI.ToyRobotA do
  use Agent
  # max x-coordinate of table top
  @table_top_x 5
  # max y-coordinate of table top
  @table_top_y :e
  # mapping of y-coordinates
  @robot_map_y_atom_to_num %{:a => 1, :b => 2, :c => 3, :d => 4, :e => 5}




  @doc """
  Places the robot to the default position of (1, A, North)

  Examples:

      iex> CLI.ToyRobotA.place
      {:ok, %CLI.Position{facing: :north, x: 1, y: :a}}
  """
  def place do
    {:ok, %CLI.Position{}}
  end

  def place(x, y, _facing) when x < 1 or y < :a or x > @table_top_x or y > @table_top_y do
    {:failure, "Invalid position"}
  end

  def place(_x, _y, facing)
  when facing not in [:north, :east, :south, :west]
  do
    {:failure, "Invalid facing direction"}
  end

  @doc """
  Places the robot to the provided position of (x, y, facing),
  but prevents it to be placed outside of the table and facing invalid direction.

  Examples:

      iex> CLI.ToyRobotA.place(1, :b, :south)
      {:ok, %CLI.Position{facing: :south, x: 1, y: :b}}

      iex> CLI.ToyRobotA.place(-1, :f, :north)
      {:failure, "Invalid position"}

      iex> CLI.ToyRobotA.place(3, :c, :north_east)
      {:failure, "Invalid facing direction"}
  """
  def place(x, y, facing) do
    # IO.puts String.upcase("A I'm placed at => #{x},#{y},#{facing}")
    {:ok, %CLI.Position{x: x, y: y, facing: facing}}
  end

  @doc """
  Provide START position to the robot as given location of (x, y, facing) and place it.
  """
  def start(x, y, facing) do
    place(x, y, facing)
  end

  def start() do
    place()
  end

  def stop(_robot, goal_x, goal_y, _cli_proc_name) when goal_x < 1 or goal_y < :a or goal_x > @table_top_x or goal_y > @table_top_y do
    {:failure, "Invalid STOP position"}
  end

  @doc """
  Provide GOAL positions to the robot as given location of [(x1, y1),(x2, y2),..] and plan the path from START to these locations.
  Passing the CLI Server process name that will be used to send robot's current status after each action is taken.
  Spawn a process and register it with name ':client_toyrobotA' which is used by CLI Server to send an
  indication for the presence of obstacle ahead of robot's current position and facing.
  """

  def get_posB() do
    Process.sleep(10)
    Agent.get(:your_map_name, fn map -> Map.get(map, :robotB) end )
  end

  defmodule SortedListStruct do
    defstruct value: -1, index: -1
  end

  def dist_from_A(%CLI.Position{x: x, y: y, facing: facing} = robot, goal_locs, i) do
    y_map_atom_to_int = %{:a => 1, :b => 2, :c => 3, :d => 4, :e => 5}
    y_int = y_map_atom_to_int[y]
    y_dest_int = y_map_atom_to_int[String.to_atom(Enum.at(Enum.at(goal_locs, i), 1))]
    {k, ""} = (Integer.parse(Enum.at(Enum.at(goal_locs, i), 0)))
    abs(k - x) + abs(y_dest_int - y_int)
  end

  def add_index(dist_list, goal_locs, i, new_list) do
    if (i < Enum.count(goal_locs)) do
      cell_to_insert = %SortedListStruct{value: Enum.at(dist_list, i), index: i}
      new_list = [cell_to_insert | new_list]
      i = i + 1
      add_index(dist_list, goal_locs, i, new_list)
    else
      new_list
    end
  end


  def dist(%CLI.Position{x: x, y: y, facing: facing} = robot, goal_locs, i, index_list, dist_list) do
    index_list = index_list ++ [i]
    distance = dist_from_A(%CLI.Position{x: x, y: y, facing: facing} = robot, goal_locs, i)
    dist_list = dist_list ++ [distance]
    i = i + 1
    if i < Enum.count(goal_locs) do
      dist(robot, goal_locs, i, index_list, dist_list)
    else
    new_list = []
    new_list = add_index(dist_list, goal_locs, 0, new_list)
    new_list = Enum.sort(new_list, fn x, y -> x.value < y.value end)
    # IO.inspect(new_list)
    new_list
    end
  end

  defp make_int(main, i, new_list) do
    if(i >= 0) do
      new_list =
      if (rem(i, 2) == 0) do
        {k, ""} = Integer.parse(Enum.at(main, i))
        new_list = new_list ++ [k]
        new_list
      else
        new_list
      end
      i = i - 1
      make_int(main, i, new_list)
    else
      new_list
    end
  end

  defp sort_B() do
    string = get_posB()
    main = String.slice(string, 4..-1)
    main = String.split(main, "", trim: true)
    main = Enum.reject(main, fn x -> x in [","] end)
    new_list = []
    new_list = make_int(main, Enum.count(main) - 1, new_list)
    sorted_B = []
    sorted_B = add_index(new_list, new_list, 0, sorted_B)
    sorted_B =  Enum.sort(sorted_B, fn x, y -> x.value < y.value end)
    # IO.inspect(sorted_B)
    sorted_B
  end

  def give_A(a_data) do
    {:ok, pid} = Agent.start_link(fn -> %{} end)
    Process.register(pid, :give_info_A)
    Agent.update(:give_info_A, fn list -> a_data end)
    # Agent.update(agent, fn list -> ["eggs" | list] end)
  end

  def set_goal(a_data, b_data, i, goal_locs) do
    if(i < Map.count(a_data)) do
      k = Enum.at(a_data, i)
      j = Enum.at(b_data, i)
      if((k.value <= j.value) and (k.index <= j.index)) do
        goal_A = Enum.at(goal_locs, k.index)
        # go_to_goal(goal_A)
      end
    end
  end

  def stop(%CLI.Position{x: x, y: y, facing: facing} = robot, goal_locs, cli_proc_name) do
    index_list = []
    dist_list = []
    a_data = dist(%CLI.Position{x: x, y: y, facing: facing} = robot, goal_locs, 0, index_list, dist_list)
    b_data = sort_B()
    give_A(a_data)
    # set_goal(a_data, b_data, 0, goal_locs)
    IO.inspect(b_data)
  end

  @doc """
  Send Toy Robot's current status i.e. location (x, y) and facing
  to the CLI Server process after each action is taken.
  Listen to the CLI Server and wait for the message indicating the presence of obstacle.
  The message with the format: '{:obstacle_presence, < true or false >}'.
  """
  def send_robot_status(%CLI.Position{x: x, y: y, facing: facing} = _robot, cli_proc_name) do
    send(cli_proc_name, {:toyrobotA_status, x, y, facing})
    # IO.puts("Sent by Toy Robot Client: #{x}, #{y}, #{facing}")
    listen_from_server()
  end

  @doc """
  Listen to the CLI Server and wait for the message indicating the presence of obstacle.
  The message with the format: '{:obstacle_presence, < true or false >}'.
  """
  def listen_from_server() do
    receive do
      {:obstacle_presence, is_obs_ahead} ->
        is_obs_ahead
    end
  end

  @doc """
  Provides the report of the robot's current position

  Examples:

      iex> {:ok, robot} = CLI.ToyRobotA.place(2, :b, :west)
      iex> CLI.ToyRobotA.report(robot)
      {2, :b, :west}
  """
  def report(%CLI.Position{x: x, y: y, facing: facing} = _robot) do
    {x, y, facing}
  end

  @directions_to_the_right %{north: :east, east: :south, south: :west, west: :north}
  @doc """
  Rotates the robot to the right
  """
  def right(%CLI.Position{facing: facing} = robot) do
    %CLI.Position{robot | facing: @directions_to_the_right[facing]}
  end

  @directions_to_the_left Enum.map(@directions_to_the_right, fn {from, to} -> {to, from} end)
  @doc """
  Rotates the robot to the left
  """
  def left(%CLI.Position{facing: facing} = robot) do
    %CLI.Position{robot | facing: @directions_to_the_left[facing]}
  end

  @doc """
  Moves the robot to the north, but prevents it to fall
  """
  def move(%CLI.Position{x: _, y: y, facing: :north} = robot) when y < @table_top_y do
    %CLI.Position{robot | y: Enum.find(@robot_map_y_atom_to_num, fn {_, val} -> val == Map.get(@robot_map_y_atom_to_num, y) + 1 end) |> elem(0)}
  end

  @doc """
  Moves the robot to the east, but prevents it to fall
  """
  def move(%CLI.Position{x: x, y: _, facing: :east} = robot) when x < @table_top_x do
    %CLI.Position{robot | x: x + 1}
  end

  @doc """
  Moves the robot to the south, but prevents it to fall
  """
  def move(%CLI.Position{x: _, y: y, facing: :south} = robot) when y > :a do
    %CLI.Position{robot | y: Enum.find(@robot_map_y_atom_to_num, fn {_, val} -> val == Map.get(@robot_map_y_atom_to_num, y) - 1 end) |> elem(0)}
  end

  @doc """
  Moves the robot to the west, but prevents it to fall
  """
  def move(%CLI.Position{x: x, y: _, facing: :west} = robot) when x > 1 do
    %CLI.Position{robot | x: x - 1}
  end

  @doc """
  Does not change the position of the robot.
  This function used as fallback if the robot cannot move outside the table
  """
  def move(robot), do: robot

  def failure do
    raise "Connection has been lost"
  end
end
