defmodule Task4CClientRobotA do
  # max x-coordinate of table top
  @table_top_x 6
  # max y-coordinate of table top
  @table_top_y :f
  # mapping of y-coordinates
  @robot_map_y_atom_to_num %{:a => 1, :b => 2, :c => 3, :d => 4, :e => 5, :f => 6}
  defmodule SortedListStruct do
    @derive Jason.Encoder
    defstruct value: -1, index: -1
  end

  @doc """
  Places the robot to the default position of (1, A, North)

  Examples:

      iex> Task4CClientRobotA.place
      {:ok, %Task4CClientRobotA.Position{facing: :north, x: 1, y: :a}}
  """
  def place do
    {:ok, %Task4CClientRobotA.Position{}}
  end

  def place(x, y, _facing) when x < 1 or y < :a or x > @table_top_x or y > @table_top_y do
    {:failure, "Invalid position"}
  end

  def place(_x, _y, facing) when facing not in [:north, :east, :south, :west] do
    {:failure, "Invalid facing direction"}
  end

  @doc """
  Places the robot to the provided position of (x, y, facing),
  but prevents it to be placed outside of the table and facing invalid direction.

  Examples:

      iex> Task4CClientRobotA.place(1, :b, :south)
      {:ok, %Task4CClientRobotA.Position{facing: :south, x: 1, y: :b}}

      iex> Task4CClientRobotA.place(-1, :f, :north)
      {:failure, "Invalid position"}

      iex> Task4CClientRobotA.place(3, :c, :north_east)
      {:failure, "Invalid facing direction"}
  """
  def place(x, y, facing) do
    {:ok, %Task4CClientRobotA.Position{x: x, y: y, facing: facing}}
  end

  @doc """
  Provide START position to the robot as given location of (x, y, facing) and place it.
  """
  def start(x, y, facing) do
    place(x, y, facing)
  end

  @doc """
  Main function to initiate the sequence of tasks to achieve by the Client Robot A,
  such as connect to the Phoenix server, get the robot A's start and goal locations to be traversed.
  Call the respective functions from this module and others as needed.
  You may create extra helper functions as needed.
  """
  def main do
    {:ok, _response, channel_status, channel_position} =
      Task4CClientRobotA.PhoenixSocketClient.connect_server()

    {:ok, position} = get_start_pos(channel_position)
    new = String.replace(position, " ", "")
    str = String.split(new, ",")
    {x, ""} = Integer.parse(Enum.at(str, 0))
    y = String.to_atom(Enum.at(str, 1))
    facing = String.to_atom(Enum.at(str, 2))
    robot_start = %Task4CClientRobotA.Position{x: x, y: y, facing: facing}
    start(x, y, facing)
    {:ok, goal_locs} = get_goal_locs(channel_position)
    {:ok, goal_locs_cell} = get_goal_locs_cell(channel_position)
    list_ret = []
    goalssssss = make_goal_list_for_cells(goal_locs_cell, list_ret)
    # IO.inspect(goalssssss)
    # IO.inspect(goal_locs)
    # goal_locs = Enum.reverse(goal_locs)
    # goalssssss = Enum.reverse(goalssssss)
    goal_locs = stop(robot_start, goal_locs, channel_status, channel_position, goalssssss)
    Process.sleep(5000)
    broadcast_stop(channel_position)
    rob = get_correct_robot_position(channel_position)
  end
  def check_if_goal_reached(goal_list, robot) do
    x = Integer.to_string(robot.x)
    y = Atom.to_string(robot.y)
    goal = [x, y]
    bool = Enum.member?(goal_list, goal)
  end
  def make_goal_list_for_cells(goal_locs_cell, list_ret) do
    if Enum.empty?(goal_locs_cell) == true do
      list_ret
    else
      n = Enum.at(goal_locs_cell, 0)
      list = get_goal(n)
      list_ret = list_ret ++ [list]
      goal_locs_cell = List.delete_at(goal_locs_cell, 0)
      make_goal_list_for_cells(goal_locs_cell, list_ret)
    end
  end

  def get_goal(n) do
    map = %{1 => "a", 2 => "b", 3 => "c", 4 => "d", 5 => "e", 6 => "f"}
    n = String.to_integer(n)

    list =
      cond do
        n >= 1 and n <= 5 ->
          x1 = to_string(n)
          x2 = to_string(n + 1)
          y1 = map[1]
          y2 = map[2]
          lst = [[x1, y1], [x1, y2], [x2, y1], [x2, y2]]

        # lst = [x1, y1]

        n >= 6 and n <= 10 ->
          x1 = to_string(n - 5)
          x2 = to_string(n - 5 + 1)
          y1 = map[2]
          y2 = map[3]
          # lst = [x1,y1,x1,y2,x2,y1,x2,y2]
          lst = [[x1, y1], [x1, y2], [x2, y1], [x2, y2]]

        # lst = [x1, y1]

        n >= 11 and n <= 15 ->
          x1 = to_string(n - 10)
          x2 = to_string(n - 10 + 1)
          y1 = map[3]
          y2 = map[4]
          # lst = [x1,y1,x1,y2,x2,y1,x2,y2]
          lst = [[x1, y1], [x1, y2], [x2, y1], [x2, y2]]

        # lst = [x1, y1]

        n >= 16 and n <= 20 ->
          x1 = to_string(n - 15)
          x2 = to_string(n - 15 + 1)
          y1 = map[4]
          y2 = map[5]
          # lst = [x1, y1]
          lst = [[x1, y1], [x1, y2], [x2, y1], [x2, y2]]

        # lst = [x1,y1,x1,y2,x2,y1,x2,y2]
        n >= 21 and n <= 25 ->
          x1 = to_string(n - 20)
          x2 = to_string(n - 20 + 1)
          y1 = map[5]
          y2 = map[6]
          # lst = [x1,y1,x1,y2,x2,y1,x2,y2]
          # lst = [x1, y1]
          lst = [[x1, y1], [x1, y2], [x2, y1], [x2, y2]]
      end

    list
  end

  def get_goal_locs_cell(channel) do
    {:ok, goal_locs} = PhoenixClient.Channel.push(channel, "give_goal_loc_a_cell", "nil")

    goal_locs =
      if goal_locs == "goal pos not recived" do
        # Process.sleep(3000)
        {:ok, goal_locs} = get_goal_locs(channel)
        goal_locs
      else
        goal_locs
      end

    {:ok, goal_locs}
  end

  def broadcast_stop(channel_position) do
    {:ok, reply} = PhoenixClient.Channel.push(channel_position, "stop_a", "nil")
  end

  def correct_X(
        %Task4CClientRobotA.Position{x: x, y: y, facing: facing} = robot,
        goal_x,
        goal_y,
        channel_status,
        channel_position,
        goal_list
      ) do
    %Task4CClientRobotA.Position{x: x, y: y, facing: facing} = robot

    if(goal_x == x) do
      # is_obs = Task4CClientRobotA.PhoenixSocketClient.send_robot_status(channel_status,channel_position,robot)
      go_to_goal(robot, goal_x, goal_y, channel_status, channel_position, goal_list)
      {:ok, robot}
    else
      is_obs =
        Task4CClientRobotA.PhoenixSocketClient.send_robot_status(
          channel_status,
          channel_position,
          robot
        )

      if x > goal_x do
        if facing != :west do
          robot = right(robot)
          %Task4CClientRobotA.Position{x: x, y: y, facing: facing} = robot
          # send_robot_status(robot, channel_status, channel_position)
          # is_obs = check_for_obs(robot,channel_status, channel_position)
          correct_X(robot, goal_x, goal_y, channel_status, channel_position,goal_list)
        else
          %Task4CClientRobotA.Position{x: x, y: y, facing: facing} = robot
          # is_obs = check_for_obs(robot,channel_status, channel_position)

          if(is_obs) do
            # IO.puts("Obstacle at #{x}, #{y}, #{facing}")
            objInX_west(robot, goal_x, goal_y, channel_status, channel_position, repeat = 0,goal_list)
            %Task4CClientRobotA.Position{x: x, y: y, facing: facing} = robot
          else
            robot = move(robot)
            %Task4CClientRobotA.Position{x: x, y: y, facing: facing} = robot
            correct_X(robot, goal_x, goal_y, channel_status, channel_position,goal_list)
          end
        end

        # send_robot_status(robot, channel_status, channel_position)
      else
        if x < goal_x do
          # is_obs = Task4CClientRobotA.PhoenixSocketClient.send_robot_status(channel_status,channel_position,robot)
          %Task4CClientRobotA.Position{x: x, y: y, facing: facing} = robot

          if facing != :east do
            robot = right(robot)
            %Task4CClientRobotA.Position{x: x, y: y, facing: facing} = robot
            # send_robot_status(robot, channel_status, channel_position)
            # is_obs = check_for_obs(robot,channel_status, channel_position)
            correct_X(robot, goal_x, goal_y, channel_status, channel_position,goal_list)
          else
            %Task4CClientRobotA.Position{x: x, y: y, facing: facing} = robot
            # is_obs = check_for_obs(robot,channel_status, channel_position)

            if(is_obs) do
              # IO.put("Obstacle at #{x + 1}, #{y}")
              # IO.puts("Obstacle at #{x}, #{y}, #{facing}")
              objInX_east(robot, goal_x, goal_y, channel_status, channel_position, repeat = 0,goal_list)
              %Task4CClientRobotA.Position{x: x, y: y, facing: facing} = robot
            else
              robot = move(robot)
              %Task4CClientRobotA.Position{x: x, y: y, facing: facing} = robot
              correct_X(robot, goal_x, goal_y, channel_status, channel_position,goal_list)
            end
          end
        end
      end
    end
  end

  def objInY_north(
        %Task4CClientRobotA.Position{x: x, y: y, facing: facing} = robot,
        goal_x,
        goal_y,
        channel_status,
        channel_position,
        repeat,
        goal_list
      ) do
    %Task4CClientRobotA.Position{x: x, y: y, facing: facing} = robot

    # make sure bot is facing north
    # IO.puts("in north")
    # turn and right and face north
    # turn and move left and face north
    if x == 1 or repeat == 1 do
      # IO.puts("in 1")
      robot = right(robot)
      %Task4CClientRobotA.Position{x: x, y: y, facing: facing} = robot

      is_obs =
        Task4CClientRobotA.PhoenixSocketClient.send_robot_status(
          channel_status,
          channel_position,
          robot
        )

      if(is_obs) do
        robot = right(robot)
        %Task4CClientRobotA.Position{x: x, y: y, facing: facing} = robot

        is_obs =
          Task4CClientRobotA.PhoenixSocketClient.send_robot_status(
            channel_status,
            channel_position,
            robot
          )

        robot = move(robot)
        %Task4CClientRobotA.Position{x: x, y: y, facing: facing} = robot

        is_obs =
          Task4CClientRobotA.PhoenixSocketClient.send_robot_status(
            channel_status,
            channel_position,
            robot
          )

        robot = left(robot)
        %Task4CClientRobotA.Position{x: x, y: y, facing: facing} = robot

        is_obs =
          Task4CClientRobotA.PhoenixSocketClient.send_robot_status(
            channel_status,
            channel_position,
            robot
          )

        if(is_obs) do
          objInX_east(
            %Task4CClientRobotA.Position{x: x, y: y, facing: facing} = robot,
            goal_x,
            goal_y,
            channel_status,
            channel_position,
            repeat = 0,
            goal_list
          )
        else
          robot = move(robot)
          %Task4CClientRobotA.Position{x: x, y: y, facing: facing} = robot

          # is_obs = Task4CClientRobotA.PhoenixSocketClient.send_robot_status(channel_status,channel_position,robot)
          go_to_goal(robot, goal_x, goal_y, channel_status, channel_position, goal_list)
        end

        %Task4CClientRobotA.Position{x: x, y: y, facing: facing} = robot
      else
        robot = move(robot)
        %Task4CClientRobotA.Position{x: x, y: y, facing: facing} = robot

        is_obs =
          Task4CClientRobotA.PhoenixSocketClient.send_robot_status(
            channel_status,
            channel_position,
            robot
          )

        robot = left(robot)

        is_obs =
          Task4CClientRobotA.PhoenixSocketClient.send_robot_status(
            channel_status,
            channel_position,
            robot
          )

        %Task4CClientRobotA.Position{x: x, y: y, facing: facing} = robot

        if is_obs do
          repeat = 1
          objInY_north(robot, goal_x, goal_y, channel_status, channel_position, repeat,goal_list)
        else
          robot = move(robot)
          %Task4CClientRobotA.Position{x: x, y: y, facing: facing} = robot

          # is_obs = Task4CClientRobotA.PhoenixSocketClient.send_robot_status(channel_status,channel_position,robot)
          if x != goal_x do
            correct_X(robot, goal_x, goal_y, channel_status, channel_position,goal_list)
          else
            go_to_goal(robot, goal_x, goal_y, channel_status, channel_position, goal_list)
          end
        end

        %Task4CClientRobotA.Position{x: x, y: y, facing: facing} = robot

        # IO.puts("exited if")
      end
    else
      # IO.puts("in 2")
      robot = left(robot)
      %Task4CClientRobotA.Position{x: x, y: y, facing: facing} = robot

      is_obs =
        Task4CClientRobotA.PhoenixSocketClient.send_robot_status(
          channel_status,
          channel_position,
          robot
        )

      if(is_obs) do
        robot = left(robot)
        %Task4CClientRobotA.Position{x: x, y: y, facing: facing} = robot

        is_obs =
          Task4CClientRobotA.PhoenixSocketClient.send_robot_status(
            channel_status,
            channel_position,
            robot
          )

        robot = move(robot)
        %Task4CClientRobotA.Position{x: x, y: y, facing: facing} = robot

        is_obs =
          Task4CClientRobotA.PhoenixSocketClient.send_robot_status(
            channel_status,
            channel_position,
            robot
          )

        robot = right(robot)
        %Task4CClientRobotA.Position{x: x, y: y, facing: facing} = robot

        is_obs =
          Task4CClientRobotA.PhoenixSocketClient.send_robot_status(
            channel_status,
            channel_position,
            robot
          )

        if(is_obs) do
          objInX_west(
            %Task4CClientRobotA.Position{x: x, y: y, facing: facing} = robot,
            goal_x,
            goal_y,
            channel_status,
            channel_position,
            repeat = 0,
            goal_list
          )
        else
          robot = move(robot)
          %Task4CClientRobotA.Position{x: x, y: y, facing: facing} = robot

          # is_obs = Task4CClientRobotA.PhoenixSocketClient.send_robot_status(channel_status,channel_position,robot)
          go_to_goal(robot, goal_x, goal_y, channel_status, channel_position, goal_list)
        end

        %Task4CClientRobotA.Position{x: x, y: y, facing: facing} = robot
      else
        robot = move(robot)
        %Task4CClientRobotA.Position{x: x, y: y, facing: facing} = robot

        is_obs =
          Task4CClientRobotA.PhoenixSocketClient.send_robot_status(
            channel_status,
            channel_position,
            robot
          )

        robot = right(robot)
        %Task4CClientRobotA.Position{x: x, y: y, facing: facing} = robot

        is_obs =
          Task4CClientRobotA.PhoenixSocketClient.send_robot_status(
            channel_status,
            channel_position,
            robot
          )

        if is_obs do
          repeat = 0
          objInY_north(robot, goal_x, goal_y, channel_status, channel_position, repeat,goal_list)
        else
          robot = move(robot)

          # is_obs = Task4CClientRobotA.PhoenixSocketClient.send_robot_status(channel_status,channel_position,robot)
          %Task4CClientRobotA.Position{x: x, y: y, facing: facing} = robot

          if x != goal_x do
            correct_X(robot, goal_x, goal_y, channel_status, channel_position,goal_list)
          else
            go_to_goal(robot, goal_x, goal_y, channel_status, channel_position, goal_list)
          end
        end

        %Task4CClientRobotA.Position{x: x, y: y, facing: facing} = robot
        # IO.puts("exited else")
      end
    end

    %Task4CClientRobotA.Position{x: x, y: y, facing: facing} = robot
    # IO.puts("#{x}, #{y}, #{facing}")
    # call the base go_to_goal func at this point
  end

  def objInY_south(
        %Task4CClientRobotA.Position{x: x, y: y, facing: facing} = robot,
        goal_x,
        goal_y,
        channel_status,
        channel_position,
        repeat,
        goal_list
      ) do
    %Task4CClientRobotA.Position{x: x, y: y, facing: facing} = robot
    # turn, move left and face south
    # turn, move right and go south
    if x == 1 or repeat == 1 do
      robot = left(robot)
      %Task4CClientRobotA.Position{x: x, y: y, facing: facing} = robot

      is_obs =
        Task4CClientRobotA.PhoenixSocketClient.send_robot_status(
          channel_status,
          channel_position,
          robot
        )

      if(is_obs) do
        robot = left(robot)
        %Task4CClientRobotA.Position{x: x, y: y, facing: facing} = robot

        is_obs =
          Task4CClientRobotA.PhoenixSocketClient.send_robot_status(
            channel_status,
            channel_position,
            robot
          )

        robot = move(robot)
        %Task4CClientRobotA.Position{x: x, y: y, facing: facing} = robot

        is_obs =
          Task4CClientRobotA.PhoenixSocketClient.send_robot_status(
            channel_status,
            channel_position,
            robot
          )

        robot = right(robot)
        %Task4CClientRobotA.Position{x: x, y: y, facing: facing} = robot

        is_obs =
          Task4CClientRobotA.PhoenixSocketClient.send_robot_status(
            channel_status,
            channel_position,
            robot
          )

        if(is_obs) do
          objInX_east(
            %Task4CClientRobotA.Position{x: x, y: y, facing: facing} = robot,
            goal_x,
            goal_y,
            channel_status,
            channel_position,
            repeat = 0,
            goal_list
          )
        else
          robot = move(robot)
          %Task4CClientRobotA.Position{x: x, y: y, facing: facing} = robot

          # is_obs = Task4CClientRobotA.PhoenixSocketClient.send_robot_status(channel_status,channel_position,robot)
          go_to_goal(robot, goal_x, goal_y, channel_status, channel_position, goal_list)
        end

        %Task4CClientRobotA.Position{x: x, y: y, facing: facing} = robot
      else
        robot = move(robot)
        %Task4CClientRobotA.Position{x: x, y: y, facing: facing} = robot

        is_obs =
          Task4CClientRobotA.PhoenixSocketClient.send_robot_status(
            channel_status,
            channel_position,
            robot
          )

        robot = right(robot)
        %Task4CClientRobotA.Position{x: x, y: y, facing: facing} = robot

        is_obs =
          Task4CClientRobotA.PhoenixSocketClient.send_robot_status(
            channel_status,
            channel_position,
            robot
          )

        if is_obs do
          repeat = 1
          objInY_south(robot, goal_x, goal_y, channel_status, channel_position, repeat,goal_list)
        else
          robot = move(robot)
          %Task4CClientRobotA.Position{x: x, y: y, facing: facing} = robot

          # is_obs = Task4CClientRobotA.PhoenixSocketClient.send_robot_status(channel_status,channel_position,robot)
          if x != goal_x do
            correct_X(robot, goal_x, goal_y, channel_status, channel_position,goal_list)
          else
            go_to_goal(robot, goal_x, goal_y, channel_status, channel_position, goal_list)
          end
        end

        %Task4CClientRobotA.Position{x: x, y: y, facing: facing} = robot
        # IO.puts("exited else")
      end
    else
      robot = right(robot)
      %Task4CClientRobotA.Position{x: x, y: y, facing: facing} = robot

      is_obs =
        Task4CClientRobotA.PhoenixSocketClient.send_robot_status(
          channel_status,
          channel_position,
          robot
        )

      if(is_obs) do
        robot = right(robot)
        %Task4CClientRobotA.Position{x: x, y: y, facing: facing} = robot

        is_obs =
          Task4CClientRobotA.PhoenixSocketClient.send_robot_status(
            channel_status,
            channel_position,
            robot
          )

        robot = move(robot)
        %Task4CClientRobotA.Position{x: x, y: y, facing: facing} = robot

        is_obs =
          Task4CClientRobotA.PhoenixSocketClient.send_robot_status(
            channel_status,
            channel_position,
            robot
          )

        robot = left(robot)
        %Task4CClientRobotA.Position{x: x, y: y, facing: facing} = robot

        is_obs =
          Task4CClientRobotA.PhoenixSocketClient.send_robot_status(
            channel_status,
            channel_position,
            robot
          )

        if(is_obs) do
          objInX_west(
            %Task4CClientRobotA.Position{x: x, y: y, facing: facing} = robot,
            goal_x,
            goal_y,
            channel_status,
            channel_position,
            repeat = 0,
            goal_list
          )
        else
          robot = move(robot)
          %Task4CClientRobotA.Position{x: x, y: y, facing: facing} = robot

          # is_obs = Task4CClientRobotA.PhoenixSocketClient.send_robot_status(channel_status,channel_position,robot)
          go_to_goal(robot, goal_x, goal_y, channel_status, channel_position, goal_list)
        end

        %Task4CClientRobotA.Position{x: x, y: y, facing: facing} = robot
      else
        robot = move(robot)
        %Task4CClientRobotA.Position{x: x, y: y, facing: facing} = robot

        is_obs =
          Task4CClientRobotA.PhoenixSocketClient.send_robot_status(
            channel_status,
            channel_position,
            robot
          )

        robot = left(robot)

        is_obs =
          Task4CClientRobotA.PhoenixSocketClient.send_robot_status(
            channel_status,
            channel_position,
            robot
          )

        %Task4CClientRobotA.Position{x: x, y: y, facing: facing} = robot

        if is_obs do
          repeat = 0
          objInY_south(robot, goal_x, goal_y, channel_status, channel_position, repeat,goal_list)
        else
          robot = move(robot)
          %Task4CClientRobotA.Position{x: x, y: y, facing: facing} = robot

          # is_obs = Task4CClientRobotA.PhoenixSocketClient.send_robot_status(channel_status,channel_position,robot)
          if x != goal_x do
            correct_X(robot, goal_x, goal_y, channel_status, channel_position,goal_list)
          else
            go_to_goal(robot, goal_x, goal_y, channel_status, channel_position, goal_list)
          end
        end

        %Task4CClientRobotA.Position{x: x, y: y, facing: facing} = robot
        # IO.puts("exited if")
      end
    end

    %Task4CClientRobotA.Position{x: x, y: y, facing: facing} = robot
    # call the base go_to_goal func at this point
    # go_to_goal(robot, goal_x, goal_y, channel_status, channel_position,goal_list)
  end

  def objInX_west(
        %Task4CClientRobotA.Position{x: x, y: y, facing: facing} = robot,
        goal_x,
        goal_y,
        channel_status,
        channel_position,
        repeat,
        goal_list
      ) do
    %Task4CClientRobotA.Position{x: x, y: y, facing: facing} = robot
    # turn, move left and face east
    # turn, move right and go south
    if y == :a or repeat == 1 do
      robot = right(robot)
      %Task4CClientRobotA.Position{x: x, y: y, facing: facing} = robot

      is_obs =
        Task4CClientRobotA.PhoenixSocketClient.send_robot_status(
          channel_status,
          channel_position,
          robot
        )

      if(is_obs) do
        robot = right(robot)
        %Task4CClientRobotA.Position{x: x, y: y, facing: facing} = robot

        is_obs =
          Task4CClientRobotA.PhoenixSocketClient.send_robot_status(
            channel_status,
            channel_position,
            robot
          )

        robot = move(robot)
        %Task4CClientRobotA.Position{x: x, y: y, facing: facing} = robot

        is_obs =
          Task4CClientRobotA.PhoenixSocketClient.send_robot_status(
            channel_status,
            channel_position,
            robot
          )

        robot = left(robot)
        %Task4CClientRobotA.Position{x: x, y: y, facing: facing} = robot

        is_obs =
          Task4CClientRobotA.PhoenixSocketClient.send_robot_status(
            channel_status,
            channel_position,
            robot
          )

        if(is_obs) do
          objInY_north(
            %Task4CClientRobotA.Position{x: x, y: y, facing: facing} = robot,
            goal_x,
            goal_y,
            channel_status,
            channel_position,
            repeat = 0,
            goal_list
          )
        else
          robot = move(robot)
          %Task4CClientRobotA.Position{x: x, y: y, facing: facing} = robot

          # is_obs = Task4CClientRobotA.PhoenixSocketClient.send_robot_status(channel_status,channel_position,robot)
          correct_X(robot, goal_x, goal_y, channel_status, channel_position,goal_list)
        end

        %Task4CClientRobotA.Position{x: x, y: y, facing: facing} = robot
      else
        robot = move(robot)
        %Task4CClientRobotA.Position{x: x, y: y, facing: facing} = robot

        is_obs =
          Task4CClientRobotA.PhoenixSocketClient.send_robot_status(
            channel_status,
            channel_position,
            robot
          )

        robot = left(robot)

        is_obs =
          Task4CClientRobotA.PhoenixSocketClient.send_robot_status(
            channel_status,
            channel_position,
            robot
          )

        %Task4CClientRobotA.Position{x: x, y: y, facing: facing} = robot

        if is_obs do
          repeat = 1
          objInX_west(robot, goal_x, goal_y, channel_status, channel_position, repeat,goal_list)
        else
          robot = move(robot)

          # is_obs = Task4CClientRobotA.PhoenixSocketClient.send_robot_status(channel_status,channel_position,robot)
          %Task4CClientRobotA.Position{x: x, y: y, facing: facing} = robot
          go_to_goal(robot, goal_x, goal_y, channel_status, channel_position, goal_list)
        end

        %Task4CClientRobotA.Position{x: x, y: y, facing: facing} = robot
        # IO.puts("exited if")
      end
    else
      robot = left(robot)
      %Task4CClientRobotA.Position{x: x, y: y, facing: facing} = robot

      is_obs =
        Task4CClientRobotA.PhoenixSocketClient.send_robot_status(
          channel_status,
          channel_position,
          robot
        )

      if(is_obs) do
        robot = left(robot)
        %Task4CClientRobotA.Position{x: x, y: y, facing: facing} = robot

        is_obs =
          Task4CClientRobotA.PhoenixSocketClient.send_robot_status(
            channel_status,
            channel_position,
            robot
          )

        robot = move(robot)
        %Task4CClientRobotA.Position{x: x, y: y, facing: facing} = robot

        is_obs =
          Task4CClientRobotA.PhoenixSocketClient.send_robot_status(
            channel_status,
            channel_position,
            robot
          )

        robot = right(robot)
        %Task4CClientRobotA.Position{x: x, y: y, facing: facing} = robot

        is_obs =
          Task4CClientRobotA.PhoenixSocketClient.send_robot_status(
            channel_status,
            channel_position,
            robot
          )

        if(is_obs) do
          objInY_south(
            %Task4CClientRobotA.Position{x: x, y: y, facing: facing} = robot,
            goal_x,
            goal_y,
            channel_status,
            channel_position,
            repeat = 0,
            goal_list
          )
        else
          robot = move(robot)
          %Task4CClientRobotA.Position{x: x, y: y, facing: facing} = robot

          # is_obs = Task4CClientRobotA.PhoenixSocketClient.send_robot_status(channel_status,channel_position,robot)
          correct_X(robot, goal_x, goal_y, channel_status, channel_position,goal_list)
        end

        %Task4CClientRobotA.Position{x: x, y: y, facing: facing} = robot
      else
        robot = move(robot)
        %Task4CClientRobotA.Position{x: x, y: y, facing: facing} = robot

        is_obs =
          Task4CClientRobotA.PhoenixSocketClient.send_robot_status(
            channel_status,
            channel_position,
            robot
          )

        robot = right(robot)
        %Task4CClientRobotA.Position{x: x, y: y, facing: facing} = robot

        is_obs =
          Task4CClientRobotA.PhoenixSocketClient.send_robot_status(
            channel_status,
            channel_position,
            robot
          )

        if is_obs do
          repeat = 0
          objInX_west(robot, goal_x, goal_y, channel_status, channel_position, repeat,goal_list)
        else
          robot = move(robot)
          %Task4CClientRobotA.Position{x: x, y: y, facing: facing} = robot

          # is_obs = Task4CClientRobotA.PhoenixSocketClient.send_robot_status(channel_status,channel_position,robot)
          go_to_goal(robot, goal_x, goal_y, channel_status, channel_position, goal_list)
        end

        %Task4CClientRobotA.Position{x: x, y: y, facing: facing} = robot
        # IO.puts("exited else")
      end
    end

    %Task4CClientRobotA.Position{x: x, y: y, facing: facing} = robot
    # call the base go_to_goal func at this point
    # go_to_goal(robot, goal_x, goal_y, channel_status, channel_position,goal_list)
  end

  def objInX_east(
        %Task4CClientRobotA.Position{x: x, y: y, facing: facing} = robot,
        goal_x,
        goal_y,
        channel_status,
        channel_position,
        repeat,
        goal_list
      ) do
    # make sure bot is facing east before running this func
    # IO.puts("in east")

    %Task4CClientRobotA.Position{x: x, y: y, facing: facing} = robot

    # turn, move left and face west
    # turn, move right and face east//
    if y == :a or repeat == 1 do
      # boundry case
      # IO.puts("in y=a")
      robot = left(robot)
      %Task4CClientRobotA.Position{x: x, y: y, facing: facing} = robot

      is_obs =
        Task4CClientRobotA.PhoenixSocketClient.send_robot_status(
          channel_status,
          channel_position,
          robot
        )

      if(is_obs) do
        robot = left(robot)
        %Task4CClientRobotA.Position{x: x, y: y, facing: facing} = robot

        is_obs =
          Task4CClientRobotA.PhoenixSocketClient.send_robot_status(
            channel_status,
            channel_position,
            robot
          )

        robot = move(robot)
        %Task4CClientRobotA.Position{x: x, y: y, facing: facing} = robot

        is_obs =
          Task4CClientRobotA.PhoenixSocketClient.send_robot_status(
            channel_status,
            channel_position,
            robot
          )

        robot = right(robot)
        %Task4CClientRobotA.Position{x: x, y: y, facing: facing} = robot

        is_obs =
          Task4CClientRobotA.PhoenixSocketClient.send_robot_status(
            channel_status,
            channel_position,
            robot
          )

        if(is_obs) do
          objInY_north(
            %Task4CClientRobotA.Position{x: x, y: y, facing: facing} = robot,
            goal_x,
            goal_y,
            channel_status,
            channel_position,
            repeat = 0,
            goal_list
          )
        else
          robot = move(robot)
          %Task4CClientRobotA.Position{x: x, y: y, facing: facing} = robot

          # is_obs = Task4CClientRobotA.PhoenixSocketClient.send_robot_status(channel_status,channel_position,robot)
          correct_X(robot, goal_x, goal_y, channel_status, channel_position,goal_list)
        end

        %Task4CClientRobotA.Position{x: x, y: y, facing: facing} = robot
      else
        robot = move(robot)
        %Task4CClientRobotA.Position{x: x, y: y, facing: facing} = robot

        is_obs =
          Task4CClientRobotA.PhoenixSocketClient.send_robot_status(
            channel_status,
            channel_position,
            robot
          )

        robot = right(robot)
        %Task4CClientRobotA.Position{x: x, y: y, facing: facing} = robot

        is_obs =
          Task4CClientRobotA.PhoenixSocketClient.send_robot_status(
            channel_status,
            channel_position,
            robot
          )

        if is_obs do
          repeat = 1
          objInX_east(robot, goal_x, goal_y, channel_status, channel_position, repeat,goal_list)
        else
          robot = move(robot)
          %Task4CClientRobotA.Position{x: x, y: y, facing: facing} = robot
          go_to_goal(robot, goal_x, goal_y, channel_status, channel_position, goal_list)
        end

        %Task4CClientRobotA.Position{x: x, y: y, facing: facing} = robot

        # is_obs = Task4CClientRobotA.PhoenixSocketClient.send_robot_status(channel_status,channel_position,robot)
        # IO.puts("exited else")
      end
    else
      # IO.puts("in else")
      ##################
      robot = left(robot)
      %Task4CClientRobotA.Position{x: x, y: y, facing: facing} = robot

      is_obs =
        Task4CClientRobotA.PhoenixSocketClient.send_robot_status(
          channel_status,
          channel_position,
          robot
        )

      if(is_obs) do
        # IO.puts("in isobs")
        robot = right(robot)
        %Task4CClientRobotA.Position{x: x, y: y, facing: facing} = robot

        is_obs =
          Task4CClientRobotA.PhoenixSocketClient.send_robot_status(
            channel_status,
            channel_position,
            robot
          )

        robot = move(robot)
        %Task4CClientRobotA.Position{x: x, y: y, facing: facing} = robot

        is_obs =
          Task4CClientRobotA.PhoenixSocketClient.send_robot_status(
            channel_status,
            channel_position,
            robot
          )

        robot = left(robot)
        %Task4CClientRobotA.Position{x: x, y: y, facing: facing} = robot

        is_obs =
          Task4CClientRobotA.PhoenixSocketClient.send_robot_status(
            channel_status,
            channel_position,
            robot
          )

        if(is_obs) do
          objInY_south(
            %Task4CClientRobotA.Position{x: x, y: y, facing: facing} = robot,
            goal_x,
            goal_y,
            channel_status,
            channel_position,
            repeat = 0,
            goal_list
          )
        else
          robot = move(robot)
          %Task4CClientRobotA.Position{x: x, y: y, facing: facing} = robot

          # is_obs = Task4CClientRobotA.PhoenixSocketClient.send_robot_status(channel_status,channel_position,robot)
          correct_X(robot, goal_x, goal_y, channel_status, channel_position,goal_list)
        end

        %Task4CClientRobotA.Position{x: x, y: y, facing: facing} = robot
      else
        # IO.puts("in else isobs")
        robot = move(robot)
        %Task4CClientRobotA.Position{x: x, y: y, facing: facing} = robot

        is_obs =
          Task4CClientRobotA.PhoenixSocketClient.send_robot_status(
            channel_status,
            channel_position,
            robot
          )

        ###############
        robot = right(robot)

        is_obs =
          Task4CClientRobotA.PhoenixSocketClient.send_robot_status(
            channel_status,
            channel_position,
            robot
          )

        %Task4CClientRobotA.Position{x: x, y: y, facing: facing} = robot

        if is_obs do
          # IO.puts("in unwanted")
          repeat = 0
          objInX_east(robot, goal_x, goal_y, channel_status, channel_position, repeat,goal_list)
        else
          # IO.puts("in wanted")
          robot = move(robot)
          %Task4CClientRobotA.Position{x: x, y: y, facing: facing} = robot

          # is_obs = Task4CClientRobotA.PhoenixSocketClient.send_robot_status(channel_status,channel_position,robot)
          go_to_goal(robot, goal_x, goal_y, channel_status, channel_position, goal_list)
        end

        %Task4CClientRobotA.Position{x: x, y: y, facing: facing} = robot
        # IO.puts("exited if")
      end
    end

    %Task4CClientRobotA.Position{x: x, y: y, facing: facing} = robot
    # call the base go_to_goal func at this point
    # go_to_goal(robot, goal_x, goal_y, channel_status, channel_position,goal_list)
  end

  # fucntio to get the start positions entered by the user on the server arena live
  def get_start_pos(channel) do
    {:ok, position} = PhoenixClient.Channel.push(channel, "give_start_posa", "nil")

    position =
      if position == "start pos not recived" do
        # Process.sleep(3000)
        {:ok, position} = get_start_pos(channel)
        position
      else
        position
      end

    {:ok, position}
  end

  # fucntion to get the goal location from the csv file in the server
  def get_goal_locs(channel) do
    {:ok, goal_locs} = PhoenixClient.Channel.push(channel, "give_goal_loc_a", "nil")

    goal_locs =
      if goal_locs == "goal pos not recived" do
        # Process.sleep(3000)
        {:ok, goal_locs} = get_goal_locs(channel)
        goal_locs
      else
        goal_locs
      end

    {:ok, goal_locs}
  end

  def send_goal_loc(channel_position, goal_location) do
    {:ok, reply} =
      PhoenixClient.Channel.push(channel_position, "incoming_goal_loc_a", goal_location)
  end

  def go_to_goal(
        %Task4CClientRobotA.Position{x: x, y: y, facing: facing} = robot,
        goal_x,
        goal_y,
        channel_status,
        channel_position,
        goal_list
      ) do
      # IO.inspect(goal_list)
    bool = check_if_goal_reached(goal_list, robot)
    if bool == true do
      is_obs =
        Task4CClientRobotA.PhoenixSocketClient.send_robot_status(
          channel_status,
          channel_position,
          robot
        )
      robot
      # {:ok,robot}
    else
      # IO.inspect(robot)
      is_obs =
        Task4CClientRobotA.PhoenixSocketClient.send_robot_status(
          channel_status,
          channel_position,
          robot
        )

      # IO.inspect(robot)
      # IO.puts("----")
      if y < goal_y do
        if facing != :north do
          robot = right(robot)
          # is_obs = check_for_obs(robot,channel_status, channel_position)
          # send_robot_status(robot, channel_status, channel_position)
          go_to_goal(robot, goal_x, goal_y, channel_status, channel_position, goal_list)
        else
          # Task4CClientRobotA.PhoenixSocketClient.send_robot_status(channel_status,channel_position,robot)
          # Task4CClientRobotA.PhoenixSocketClient.send_robot_status(channel_status,channel_position,robot)
          if(is_obs) do
            #  IO.put("Obstacle at #{x}, #{y + 1}")
            # IO.puts("Obstacle at #{x}, #{y}, #{facing}")
            objInY_north(robot, goal_x, goal_y, channel_status, channel_position, repeat = 0,goal_list)
          else
            # %Task4CClientRobotA.Position{x: x, y: y, facing: facing} = robot
            # Task4CClientRobotA.PhoenixSocketClient.send_robot_status(channel_status,channel_pos,robot)
            robot = move(robot)

            # Task4CClientRobotA.PhoenixSocketClient.send_robot_status(channel_status,channel_position,robot)
            # send_robot_status(robot, channel_status, channel_position)
            go_to_goal(robot, goal_x, goal_y, channel_status, channel_position, goal_list)
          end
        end
      else
        if y > goal_y do
          if facing != :south do
            robot = right(robot)
            # is_obs = check_for_obs(robot,channel_status, channel_position)
            # send_robot_status(robot, channel_status, channel_position)
            go_to_goal(robot, goal_x, goal_y, channel_status, channel_position, goal_list)
          else
            # is_obs = check_for_obs(robot,channel_status, channel_position)
            if(is_obs) do
              # IO.put("Obstacle at #{x}, #{y - 1}")
              # IO.puts("Obstacle at #{x}, #{y}, #{facing}")
              objInY_south(robot, goal_x, goal_y, channel_status, channel_position, repeat = 0,goal_list)
              # IO.puts("##########################################")
              # IO.inspect(robot)
            else
              robot = move(robot)
              go_to_goal(robot, goal_x, goal_y, channel_status, channel_position, goal_list)
            end

            # send_robot_status(robot, channel_status, channel_position)
          end
        else
          if x > goal_x do
            if facing != :west do
              robot = right(robot)

              # send_robot_status(robot, channel_status, channel_position)
              # is_obs = check_for_obs(robot,channel_status, channel_position)
              go_to_goal(robot, goal_x, goal_y, channel_status, channel_position, goal_list)
            else
              # is_obs = check_for_obs(robot,channel_status, channel_position)
              if(is_obs) do
                # IO.puts("Obstacle at #{x}, #{y}, #{facing}")
                objInX_west(robot, goal_x, goal_y, channel_status, channel_position, repeat = 0,goal_list)
              else
                robot = move(robot)
                go_to_goal(robot, goal_x, goal_y, channel_status, channel_position, goal_list)
              end
            end

            # send_robot_status(robot, channel_status, channel_position)
          else
            if x < goal_x do
              # Task4CClientRobotA.PhoenixSocketClient.send_robot_status(channel_status,channel_position,robot)
              if facing != :east do
                robot = right(robot)
                # send_robot_status(robot, channel_status, channel_position)
                # is_obs = check_for_obs(robot,channel_status, channel_position)
                go_to_goal(robot, goal_x, goal_y, channel_status, channel_position, goal_list)
              else
                # is_obs = check_for_obs(robot,channel_status, channel_position)
                if(is_obs) do
                  # IO.put("Obstacle at #{x + 1}, #{y}")
                  # IO.puts("Obstacle at #{x}, #{y}, #{facing}")
                  # -----
                  objInX_east(robot, goal_x, goal_y, channel_status, channel_position, repeat = 0,goal_list)
                else
                  robot = move(robot)
                  go_to_goal(robot, goal_x, goal_y, channel_status, channel_position, goal_list)
                end
              end

              # send_robot_status(robot, channel_status, channel_position)
            else
              Task4CClientRobotA.PhoenixSocketClient.send_robot_status(
                channel_status,
                channel_position,
                robot
              )

              # {:ok,robot}
            end
          end
        end
      end

    end
  end

  @doc """
  Provide GOAL positions to the robot as given location of [(x1, y1),(x2, y2),..] and plan the path from START to these locations.
  Make a call to ToyRobot.PhoenixSocketClient.send_robot_status/2 to get the indication of obstacle presence ahead of the robot.
  """
  def stop(robot, goal_locs, channel_status, channel_position, goalss) do
    # get_goal(robot, goal_locs, 0, [], channel_status,channel_position, 0, [])
    goal_locs =
      if Enum.empty?(goal_locs) == false do
        goal1 = Enum.at(goal_locs, 0)
        goal_list = Enum.at(goalss,0)
        # goal_x = goal1["x"]
        # goal_y = String.to_atom(goal1["y"])
        goal_x = String.to_integer(Enum.at(goal1, 0))
        goal_y = String.to_atom(Enum.at(goal1, 1))
        # IO.inspect({goal_x, goal_y})
        # IO.inspect({"robot_before",robot})
        robot_old = go_to_goal(robot, goal_x, goal_y, channel_status, channel_position, goal_list)
        # IO.inspect({"robot_after",robot})
        robot_corr = get_correct_robot_position(channel_position)
        goal_locs = List.delete_at(goal_locs, 0)
        goalss = List.delete_at(goalss,0)

        robot = %Task4CClientRobotA.Position{
          x: robot_corr["x"],
          y: String.to_atom(robot_corr["y"]),
          facing: String.to_atom(robot_corr["face"])
        }

        stop(robot, goal_locs, channel_status, channel_position, goalss)
      else
        goal_locs
      end

    goal_locs
  end

  def get_correct_robot_position(channel_position) do
    {:ok, robot_position} = PhoenixClient.Channel.push(channel_position, "give_roba_pos", "nil")
    robot_position
  end

  @doc """
  Provides the report of the robot's current position

  Examples:

      iex> {:ok, robot} = Task4CClientRobotA.place(2, :b, :west)
      iex> Task4CClientRobotA.report(robot)
      {2, :b, :west}
  """
  def report(%Task4CClientRobotA.Position{x: x, y: y, facing: facing} = _robot) do
    {x, y, facing}
  end

  @directions_to_the_right %{north: :east, east: :south, south: :west, west: :north}
  @doc """
  Rotates the robot to the right
  """
  def right(%Task4CClientRobotA.Position{facing: facing} = robot) do
    %Task4CClientRobotA.Position{robot | facing: @directions_to_the_right[facing]}
  end

  @directions_to_the_left Enum.map(@directions_to_the_right, fn {from, to} -> {to, from} end)
  @doc """
  Rotates the robot to the left
  """
  def left(%Task4CClientRobotA.Position{facing: facing} = robot) do
    %Task4CClientRobotA.Position{robot | facing: @directions_to_the_left[facing]}
  end

  @doc """
  Moves the robot to the north, but prevents it to fall
  """
  def move(%Task4CClientRobotA.Position{x: _, y: y, facing: :north} = robot)
      when y < @table_top_y do
    %Task4CClientRobotA.Position{
      robot
      | y:
          Enum.find(@robot_map_y_atom_to_num, fn {_, val} ->
            val == Map.get(@robot_map_y_atom_to_num, y) + 1
          end)
          |> elem(0)
    }
  end

  @doc """
  Moves the robot to the east, but prevents it to fall
  """
  def move(%Task4CClientRobotA.Position{x: x, y: _, facing: :east} = robot)
      when x < @table_top_x do
    %Task4CClientRobotA.Position{robot | x: x + 1}
  end

  @doc """
  Moves the robot to the south, but prevents it to fall
  """
  def move(%Task4CClientRobotA.Position{x: _, y: y, facing: :south} = robot) when y > :a do
    %Task4CClientRobotA.Position{
      robot
      | y:
          Enum.find(@robot_map_y_atom_to_num, fn {_, val} ->
            val == Map.get(@robot_map_y_atom_to_num, y) - 1
          end)
          |> elem(0)
    }
  end

  @doc """
  Moves the robot to the west, but prevents it to fall
  """
  def move(%Task4CClientRobotA.Position{x: x, y: _, facing: :west} = robot) when x > 1 do
    %Task4CClientRobotA.Position{robot | x: x - 1}
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
