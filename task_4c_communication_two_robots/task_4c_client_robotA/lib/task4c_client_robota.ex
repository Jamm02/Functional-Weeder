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
    # IO.inspect(goal_locs)
    goal_locs = Enum.reverse(goal_locs)
    goal_locs = stop(robot_start,goal_locs,channel_status,channel_position)
  end
  def correct_X(%Task4CClientRobotA.Position{x: x, y: y, facing: facing} = robot, goal_x, goal_y, channel_status, channel_position) do
    %Task4CClientRobotA.Position{x: x, y: y, facing: facing} = robot

    if(goal_x == x) do
      # is_obs = Task4CClientRobotA.PhoenixSocketClient.send_robot_status(channel_status,channel_position,robot)
      go_to_goal(robot, goal_x, goal_y, channel_status, channel_position)
      {:ok, robot}

    else
    is_obs = Task4CClientRobotA.PhoenixSocketClient.send_robot_status(channel_status,channel_position,robot)
    if x > goal_x do

      if (facing != :west) do
        robot = right(robot)
        %Task4CClientRobotA.Position{x: x, y: y, facing: facing} = robot
        # send_robot_status(robot, channel_status, channel_position)
        #is_obs = check_for_obs(robot,channel_status, channel_position)
        correct_X(robot, goal_x, goal_y, channel_status, channel_position)
      else
        %Task4CClientRobotA.Position{x: x, y: y, facing: facing} = robot
        # is_obs = check_for_obs(robot,channel_status, channel_position)

        if(is_obs) do
          # IO.puts("Obstacle at #{x}, #{y}, #{facing}")
          objInX_west(robot, goal_x, goal_y, channel_status, channel_position, repeat = 0)
          %Task4CClientRobotA.Position{x: x, y: y, facing: facing} = robot

        else
          robot = move(robot)
          %Task4CClientRobotA.Position{x: x, y: y, facing: facing} = robot
          correct_X(robot, goal_x, goal_y, channel_status, channel_position)
        end
      end
        # send_robot_status(robot, channel_status, channel_position)

    else if x < goal_x do
      # is_obs = Task4CClientRobotA.PhoenixSocketClient.send_robot_status(channel_status,channel_position,robot)
      %Task4CClientRobotA.Position{x: x, y: y, facing: facing} = robot

      if (facing != :east) do
        robot = right(robot)
        %Task4CClientRobotA.Position{x: x, y: y, facing: facing} = robot
        # send_robot_status(robot, channel_status, channel_position)
        #is_obs = check_for_obs(robot,channel_status, channel_position)
        correct_X(robot, goal_x, goal_y, channel_status, channel_position)

      else
        %Task4CClientRobotA.Position{x: x, y: y, facing: facing} = robot
        # is_obs = check_for_obs(robot,channel_status, channel_position)

        if(is_obs) do
          # IO.put("Obstacle at #{x + 1}, #{y}")
          # IO.puts("Obstacle at #{x}, #{y}, #{facing}")
          objInX_east(robot, goal_x, goal_y, channel_status, channel_position, repeat = 0)
          %Task4CClientRobotA.Position{x: x, y: y, facing: facing} = robot


        else
          robot = move(robot)
          %Task4CClientRobotA.Position{x: x, y: y, facing: facing} = robot
          correct_X(robot, goal_x, goal_y, channel_status, channel_position)
        end
      end
    end
  end
end
end
  def objInY_north(%Task4CClientRobotA.Position{x: x, y: y, facing: facing} = robot, goal_x, goal_y, channel_status, channel_position, repeat) do
    %Task4CClientRobotA.Position{x: x, y: y, facing: facing} = robot

    # make sure bot is facing north
    # IO.puts("in north")
    if (x == 1) or (repeat == 1)  do  #turn and right and face north
      # IO.puts("in 1")
      robot = right(robot);
      %Task4CClientRobotA.Position{x: x, y: y, facing: facing} = robot
      is_obs = Task4CClientRobotA.PhoenixSocketClient.send_robot_status(channel_status,channel_position,robot)

      if(is_obs) do
        robot = right(robot)
        %Task4CClientRobotA.Position{x: x, y: y, facing: facing} = robot
        is_obs = Task4CClientRobotA.PhoenixSocketClient.send_robot_status(channel_status,channel_position,robot)
        robot = move(robot)
        %Task4CClientRobotA.Position{x: x, y: y, facing: facing} = robot
        is_obs = Task4CClientRobotA.PhoenixSocketClient.send_robot_status(channel_status,channel_position,robot)
        robot = left(robot)
        %Task4CClientRobotA.Position{x: x, y: y, facing: facing} = robot
        is_obs = Task4CClientRobotA.PhoenixSocketClient.send_robot_status(channel_status,channel_position,robot)

        if(is_obs) do
          objInX_east(%Task4CClientRobotA.Position{x: x, y: y, facing: facing} = robot, goal_x, goal_y, channel_status, channel_position, repeat = 0)
        else
          robot = move(robot)
          %Task4CClientRobotA.Position{x: x, y: y, facing: facing} = robot
          # is_obs = Task4CClientRobotA.PhoenixSocketClient.send_robot_status(channel_status,channel_position,robot)
          go_to_goal(robot, goal_x, goal_y, channel_status, channel_position)
        end
        %Task4CClientRobotA.Position{x: x, y: y, facing: facing} = robot

      else
        robot = move(robot);
        %Task4CClientRobotA.Position{x: x, y: y, facing: facing} = robot
        is_obs = Task4CClientRobotA.PhoenixSocketClient.send_robot_status(channel_status,channel_position,robot)
        robot = left(robot);
        is_obs = Task4CClientRobotA.PhoenixSocketClient.send_robot_status(channel_status,channel_position,robot)
        %Task4CClientRobotA.Position{x: x, y: y, facing: facing} = robot
        if (is_obs) do
          repeat = 1
          objInY_north(robot, goal_x, goal_y, channel_status, channel_position, repeat)
        else
          robot = move(robot)
          %Task4CClientRobotA.Position{x: x, y: y, facing: facing} = robot
          #is_obs = Task4CClientRobotA.PhoenixSocketClient.send_robot_status(channel_status,channel_position,robot)
          if (x != goal_x) do
            correct_X(robot, goal_x, goal_y, channel_status, channel_position)
          else
            go_to_goal(robot, goal_x, goal_y, channel_status, channel_position)
          end
        end
        %Task4CClientRobotA.Position{x: x, y: y, facing: facing} = robot

        # IO.puts("exited if")
      end

    else #turn and move left and face north
      # IO.puts("in 2")
      robot = left(robot);
      %Task4CClientRobotA.Position{x: x, y: y, facing: facing} = robot
      is_obs = Task4CClientRobotA.PhoenixSocketClient.send_robot_status(channel_status,channel_position,robot)

      if(is_obs) do
        robot = left(robot)
        %Task4CClientRobotA.Position{x: x, y: y, facing: facing} = robot
        is_obs = Task4CClientRobotA.PhoenixSocketClient.send_robot_status(channel_status,channel_position,robot)
        robot = move(robot)
        %Task4CClientRobotA.Position{x: x, y: y, facing: facing} = robot
        is_obs = Task4CClientRobotA.PhoenixSocketClient.send_robot_status(channel_status,channel_position,robot)
        robot = right(robot)
        %Task4CClientRobotA.Position{x: x, y: y, facing: facing} = robot
        is_obs = Task4CClientRobotA.PhoenixSocketClient.send_robot_status(channel_status,channel_position,robot)

        if(is_obs) do
          objInX_west(%Task4CClientRobotA.Position{x: x, y: y, facing: facing} = robot, goal_x, goal_y, channel_status, channel_position, repeat = 0)
        else
          robot = move(robot)
          %Task4CClientRobotA.Position{x: x, y: y, facing: facing} = robot
          # is_obs = Task4CClientRobotA.PhoenixSocketClient.send_robot_status(channel_status,channel_position,robot)
          go_to_goal(robot, goal_x, goal_y, channel_status, channel_position)
        end
        %Task4CClientRobotA.Position{x: x, y: y, facing: facing} = robot

      else
        robot = move(robot);
        %Task4CClientRobotA.Position{x: x, y: y, facing: facing} = robot
        is_obs = Task4CClientRobotA.PhoenixSocketClient.send_robot_status(channel_status,channel_position,robot)
        robot = right(robot);
        %Task4CClientRobotA.Position{x: x, y: y, facing: facing} = robot
        is_obs = Task4CClientRobotA.PhoenixSocketClient.send_robot_status(channel_status,channel_position,robot)
        if (is_obs) do
          repeat = 0
          objInY_north(robot, goal_x, goal_y, channel_status, channel_position, repeat)
        else
          robot = move(robot)
          # is_obs = Task4CClientRobotA.PhoenixSocketClient.send_robot_status(channel_status,channel_position,robot)
          %Task4CClientRobotA.Position{x: x, y: y, facing: facing} = robot
          if (x != goal_x) do
            correct_X(robot, goal_x, goal_y, channel_status, channel_position)
          else
            go_to_goal(robot, goal_x, goal_y, channel_status, channel_position)
          end
        end
        %Task4CClientRobotA.Position{x: x, y: y, facing: facing} = robot
        # IO.puts("exited else")
      end

    end

    %Task4CClientRobotA.Position{x: x, y: y, facing: facing} = robot
    # IO.puts("#{x}, #{y}, #{facing}")
    #call the base go_to_goal func at this point

  end


  def objInY_south(%Task4CClientRobotA.Position{x: x, y: y, facing: facing} = robot, goal_x, goal_y, channel_status, channel_position, repeat) do
    %Task4CClientRobotA.Position{x: x, y: y, facing: facing} = robot
    if (x == 1) or (repeat == 1) do  #turn, move left and face south
      robot = left(robot);
      %Task4CClientRobotA.Position{x: x, y: y, facing: facing} = robot
      is_obs = Task4CClientRobotA.PhoenixSocketClient.send_robot_status(channel_status,channel_position,robot)

      if(is_obs) do
        robot = left(robot)
        %Task4CClientRobotA.Position{x: x, y: y, facing: facing} = robot
        is_obs = Task4CClientRobotA.PhoenixSocketClient.send_robot_status(channel_status,channel_position,robot)
        robot = move(robot)
        %Task4CClientRobotA.Position{x: x, y: y, facing: facing} = robot
        is_obs = Task4CClientRobotA.PhoenixSocketClient.send_robot_status(channel_status,channel_position,robot)
        robot = right(robot)
        %Task4CClientRobotA.Position{x: x, y: y, facing: facing} = robot
        is_obs = Task4CClientRobotA.PhoenixSocketClient.send_robot_status(channel_status,channel_position,robot)

        if(is_obs) do
          objInX_east(%Task4CClientRobotA.Position{x: x, y: y, facing: facing} = robot, goal_x, goal_y, channel_status, channel_position, repeat = 0)
        else
          robot = move(robot)
          %Task4CClientRobotA.Position{x: x, y: y, facing: facing} = robot
          # is_obs = Task4CClientRobotA.PhoenixSocketClient.send_robot_status(channel_status,channel_position,robot)
          go_to_goal(robot, goal_x, goal_y, channel_status, channel_position)

        end
        %Task4CClientRobotA.Position{x: x, y: y, facing: facing} = robot

      else
        robot = move(robot);
        %Task4CClientRobotA.Position{x: x, y: y, facing: facing} = robot
        is_obs = Task4CClientRobotA.PhoenixSocketClient.send_robot_status(channel_status,channel_position,robot)
        robot = right(robot);
        %Task4CClientRobotA.Position{x: x, y: y, facing: facing} = robot
        is_obs = Task4CClientRobotA.PhoenixSocketClient.send_robot_status(channel_status,channel_position,robot)
        if (is_obs) do
          repeat = 1
          objInY_south(robot, goal_x, goal_y, channel_status, channel_position, repeat)
        else
          robot = move(robot)
          %Task4CClientRobotA.Position{x: x, y: y, facing: facing} = robot
          # is_obs = Task4CClientRobotA.PhoenixSocketClient.send_robot_status(channel_status,channel_position,robot)
          if (x != goal_x) do
            correct_X(robot, goal_x, goal_y, channel_status, channel_position)
          else
            go_to_goal(robot, goal_x, goal_y, channel_status, channel_position)
          end
        end
        %Task4CClientRobotA.Position{x: x, y: y, facing: facing} = robot
        # IO.puts("exited else")
      end

    else #turn, move right and go south
      robot = right(robot);
      %Task4CClientRobotA.Position{x: x, y: y, facing: facing} = robot
      is_obs = Task4CClientRobotA.PhoenixSocketClient.send_robot_status(channel_status,channel_position,robot)

      if(is_obs) do
        robot = right(robot)
        %Task4CClientRobotA.Position{x: x, y: y, facing: facing} = robot
        is_obs = Task4CClientRobotA.PhoenixSocketClient.send_robot_status(channel_status,channel_position,robot)
        robot = move(robot)
        %Task4CClientRobotA.Position{x: x, y: y, facing: facing} = robot
        is_obs = Task4CClientRobotA.PhoenixSocketClient.send_robot_status(channel_status,channel_position,robot)
        robot = left(robot)
        %Task4CClientRobotA.Position{x: x, y: y, facing: facing} = robot
        is_obs = Task4CClientRobotA.PhoenixSocketClient.send_robot_status(channel_status,channel_position,robot)

        if(is_obs) do
          objInX_west(%Task4CClientRobotA.Position{x: x, y: y, facing: facing} = robot, goal_x, goal_y, channel_status, channel_position, repeat = 0)
        else
          robot = move(robot)
          %Task4CClientRobotA.Position{x: x, y: y, facing: facing} = robot
          # is_obs = Task4CClientRobotA.PhoenixSocketClient.send_robot_status(channel_status,channel_position,robot)
          go_to_goal(robot, goal_x, goal_y, channel_status, channel_position)
        end
        %Task4CClientRobotA.Position{x: x, y: y, facing: facing} = robot

      else
        robot = move(robot);
        %Task4CClientRobotA.Position{x: x, y: y, facing: facing} = robot
        is_obs = Task4CClientRobotA.PhoenixSocketClient.send_robot_status(channel_status,channel_position,robot)
        robot = left(robot);
        is_obs = Task4CClientRobotA.PhoenixSocketClient.send_robot_status(channel_status,channel_position,robot)
        %Task4CClientRobotA.Position{x: x, y: y, facing: facing} = robot
        if (is_obs) do
          repeat = 0
          objInY_south(robot, goal_x, goal_y, channel_status, channel_position, repeat)
        else
          robot = move(robot)
          %Task4CClientRobotA.Position{x: x, y: y, facing: facing} = robot
          # is_obs = Task4CClientRobotA.PhoenixSocketClient.send_robot_status(channel_status,channel_position,robot)
          if (x != goal_x) do
            correct_X(robot, goal_x, goal_y, channel_status, channel_position)
          else
            go_to_goal(robot, goal_x, goal_y, channel_status, channel_position)
          end
        end
        %Task4CClientRobotA.Position{x: x, y: y, facing: facing} = robot
        # IO.puts("exited if")
      end
    end
    %Task4CClientRobotA.Position{x: x, y: y, facing: facing} = robot
    #call the base go_to_goal func at this point
    # go_to_goal(robot, goal_x, goal_y, channel_status, channel_position)
  end

  def objInX_west(%Task4CClientRobotA.Position{x: x, y: y, facing: facing} = robot, goal_x, goal_y, channel_status, channel_position, repeat) do


    %Task4CClientRobotA.Position{x: x, y: y, facing: facing} = robot

    if (y == :a) or (repeat == 1) do  #turn, move left and face east
      robot = right(robot);
      %Task4CClientRobotA.Position{x: x, y: y, facing: facing} = robot
      is_obs = Task4CClientRobotA.PhoenixSocketClient.send_robot_status(channel_status,channel_position,robot)


      if(is_obs) do
        robot = right(robot)
        %Task4CClientRobotA.Position{x: x, y: y, facing: facing} = robot
        is_obs = Task4CClientRobotA.PhoenixSocketClient.send_robot_status(channel_status,channel_position,robot)
        robot = move(robot)
        %Task4CClientRobotA.Position{x: x, y: y, facing: facing} = robot
        is_obs = Task4CClientRobotA.PhoenixSocketClient.send_robot_status(channel_status,channel_position,robot)
        robot = left(robot)
        %Task4CClientRobotA.Position{x: x, y: y, facing: facing} = robot
        is_obs = Task4CClientRobotA.PhoenixSocketClient.send_robot_status(channel_status,channel_position,robot)

        if(is_obs) do
          objInY_north(%Task4CClientRobotA.Position{x: x, y: y, facing: facing} = robot, goal_x, goal_y, channel_status, channel_position, repeat = 0)
        else
          robot = move(robot)
          %Task4CClientRobotA.Position{x: x, y: y, facing: facing} = robot
          # is_obs = Task4CClientRobotA.PhoenixSocketClient.send_robot_status(channel_status,channel_position,robot)
          correct_X(robot, goal_x, goal_y, channel_status, channel_position)
        end
        %Task4CClientRobotA.Position{x: x, y: y, facing: facing} = robot

      else
        robot = move(robot);
        %Task4CClientRobotA.Position{x: x, y: y, facing: facing} = robot
        is_obs = Task4CClientRobotA.PhoenixSocketClient.send_robot_status(channel_status,channel_position,robot)
        robot = left(robot);
        is_obs = Task4CClientRobotA.PhoenixSocketClient.send_robot_status(channel_status,channel_position,robot)
        %Task4CClientRobotA.Position{x: x, y: y, facing: facing} = robot
        if (is_obs) do
          repeat = 1
          objInX_west(robot, goal_x, goal_y, channel_status, channel_position, repeat)
        else
          robot = move(robot)
          # is_obs = Task4CClientRobotA.PhoenixSocketClient.send_robot_status(channel_status,channel_position,robot)
          %Task4CClientRobotA.Position{x: x, y: y, facing: facing} = robot
          go_to_goal(robot, goal_x, goal_y, channel_status, channel_position)
        end
        %Task4CClientRobotA.Position{x: x, y: y, facing: facing} = robot
        # IO.puts("exited if")
      end


    else #turn, move right and go south

      robot = left(robot);
      %Task4CClientRobotA.Position{x: x, y: y, facing: facing} = robot
      is_obs = Task4CClientRobotA.PhoenixSocketClient.send_robot_status(channel_status,channel_position,robot)


      if(is_obs) do
        robot = left(robot)
        %Task4CClientRobotA.Position{x: x, y: y, facing: facing} = robot
        is_obs = Task4CClientRobotA.PhoenixSocketClient.send_robot_status(channel_status,channel_position,robot)
        robot = move(robot)
        %Task4CClientRobotA.Position{x: x, y: y, facing: facing} = robot
        is_obs = Task4CClientRobotA.PhoenixSocketClient.send_robot_status(channel_status,channel_position,robot)
        robot = right(robot)
        %Task4CClientRobotA.Position{x: x, y: y, facing: facing} = robot
        is_obs = Task4CClientRobotA.PhoenixSocketClient.send_robot_status(channel_status,channel_position,robot)

        if(is_obs) do
          objInY_south(%Task4CClientRobotA.Position{x: x, y: y, facing: facing} = robot, goal_x, goal_y, channel_status, channel_position, repeat = 0)
        else
          robot = move(robot)
          %Task4CClientRobotA.Position{x: x, y: y, facing: facing} = robot
          # is_obs = Task4CClientRobotA.PhoenixSocketClient.send_robot_status(channel_status,channel_position,robot)
          correct_X(robot, goal_x, goal_y, channel_status, channel_position)
        end
        %Task4CClientRobotA.Position{x: x, y: y, facing: facing} = robot

      else
        robot = move(robot);
        %Task4CClientRobotA.Position{x: x, y: y, facing: facing} = robot
        is_obs = Task4CClientRobotA.PhoenixSocketClient.send_robot_status(channel_status,channel_position,robot)
        robot = right(robot);
        %Task4CClientRobotA.Position{x: x, y: y, facing: facing} = robot
        is_obs = Task4CClientRobotA.PhoenixSocketClient.send_robot_status(channel_status,channel_position,robot)
        if (is_obs) do
          repeat = 0
          objInX_west(robot, goal_x, goal_y, channel_status, channel_position, repeat)
        else
          robot = move(robot)
          %Task4CClientRobotA.Position{x: x, y: y, facing: facing} = robot
          # is_obs = Task4CClientRobotA.PhoenixSocketClient.send_robot_status(channel_status,channel_position,robot)
          go_to_goal(robot, goal_x, goal_y, channel_status, channel_position)
        end
        %Task4CClientRobotA.Position{x: x, y: y, facing: facing} = robot
        # IO.puts("exited else")
      end

    end
    %Task4CClientRobotA.Position{x: x, y: y, facing: facing} = robot
    #call the base go_to_goal func at this point
    # go_to_goal(robot, goal_x, goal_y, channel_status, channel_position)
  end

  def objInX_east(%Task4CClientRobotA.Position{x: x, y: y, facing: facing} = robot, goal_x, goal_y, channel_status, channel_position, repeat) do

    # make sure bot is facing east before running this func
    # IO.puts("in east")

    %Task4CClientRobotA.Position{x: x, y: y, facing: facing} = robot

    if (y == :a) or (repeat == 1) do  #turn, move left and face west
                  #boundry case
      # IO.puts("in y=a")
      robot = left(robot)
      %Task4CClientRobotA.Position{x: x, y: y, facing: facing} = robot
      is_obs = Task4CClientRobotA.PhoenixSocketClient.send_robot_status(channel_status,channel_position,robot)

      if(is_obs) do
        robot = left(robot)
        %Task4CClientRobotA.Position{x: x, y: y, facing: facing} = robot
        is_obs = Task4CClientRobotA.PhoenixSocketClient.send_robot_status(channel_status,channel_position,robot)
        robot = move(robot)
        %Task4CClientRobotA.Position{x: x, y: y, facing: facing} = robot
        is_obs = Task4CClientRobotA.PhoenixSocketClient.send_robot_status(channel_status,channel_position,robot)
        robot = right(robot)
        %Task4CClientRobotA.Position{x: x, y: y, facing: facing} = robot
        is_obs = Task4CClientRobotA.PhoenixSocketClient.send_robot_status(channel_status,channel_position,robot)

        if(is_obs) do
          objInY_north(%Task4CClientRobotA.Position{x: x, y: y, facing: facing} = robot, goal_x, goal_y, channel_status, channel_position, repeat = 0)
        else
          robot = move(robot)
          %Task4CClientRobotA.Position{x: x, y: y, facing: facing} = robot
          # is_obs = Task4CClientRobotA.PhoenixSocketClient.send_robot_status(channel_status,channel_position,robot)
          correct_X(robot, goal_x, goal_y, channel_status, channel_position)
        end
        %Task4CClientRobotA.Position{x: x, y: y, facing: facing} = robot

      else
        robot = move(robot);
        %Task4CClientRobotA.Position{x: x, y: y, facing: facing} = robot
        is_obs = Task4CClientRobotA.PhoenixSocketClient.send_robot_status(channel_status,channel_position,robot)
        robot = right(robot);
        %Task4CClientRobotA.Position{x: x, y: y, facing: facing} = robot
        is_obs = Task4CClientRobotA.PhoenixSocketClient.send_robot_status(channel_status,channel_position,robot)
        if (is_obs) do
          repeat = 1
          objInX_east(robot, goal_x, goal_y, channel_status, channel_position, repeat)
        else
          robot = move(robot)
          %Task4CClientRobotA.Position{x: x, y: y, facing: facing} = robot
          go_to_goal(robot, goal_x, goal_y, channel_status, channel_position)
        end
        %Task4CClientRobotA.Position{x: x, y: y, facing: facing} = robot

        #is_obs = Task4CClientRobotA.PhoenixSocketClient.send_robot_status(channel_status,channel_position,robot)
        # IO.puts("exited else")
      end

    else #turn, move right and face east//
      # IO.puts("in else")
      robot = right(robot);
      %Task4CClientRobotA.Position{x: x, y: y, facing: facing} = robot
      is_obs = Task4CClientRobotA.PhoenixSocketClient.send_robot_status(channel_status,channel_position,robot)

      if(is_obs) do
        # IO.puts("in isobs")
        robot = right(robot)
        %Task4CClientRobotA.Position{x: x, y: y, facing: facing} = robot
        is_obs = Task4CClientRobotA.PhoenixSocketClient.send_robot_status(channel_status,channel_position,robot)

        robot = move(robot)
        %Task4CClientRobotA.Position{x: x, y: y, facing: facing} = robot
        is_obs = Task4CClientRobotA.PhoenixSocketClient.send_robot_status(channel_status,channel_position,robot)

        robot = left(robot)
        %Task4CClientRobotA.Position{x: x, y: y, facing: facing} = robot
        is_obs = Task4CClientRobotA.PhoenixSocketClient.send_robot_status(channel_status,channel_position,robot)

        if(is_obs) do
          objInY_south(%Task4CClientRobotA.Position{x: x, y: y, facing: facing} = robot, goal_x, goal_y, channel_status, channel_position, repeat = 0)
        else
          robot = move(robot)
          %Task4CClientRobotA.Position{x: x, y: y, facing: facing} = robot
          # is_obs = Task4CClientRobotA.PhoenixSocketClient.send_robot_status(channel_status,channel_position,robot)
          correct_X(robot, goal_x, goal_y, channel_status, channel_position)
        end
        %Task4CClientRobotA.Position{x: x, y: y, facing: facing} = robot

      else
        # IO.puts("in else isobs")
        robot = move(robot);
        %Task4CClientRobotA.Position{x: x, y: y, facing: facing} = robot
        is_obs = Task4CClientRobotA.PhoenixSocketClient.send_robot_status(channel_status,channel_position,robot)
        robot = left(robot);
        is_obs = Task4CClientRobotA.PhoenixSocketClient.send_robot_status(channel_status,channel_position,robot)
        %Task4CClientRobotA.Position{x: x, y: y, facing: facing} = robot

        if (is_obs) do
          # IO.puts("in unwanted")
          repeat = 0
          objInX_east(robot, goal_x, goal_y, channel_status, channel_position, repeat)
        else
          # IO.puts("in wanted")
          robot = move(robot)
          %Task4CClientRobotA.Position{x: x, y: y, facing: facing} = robot
          # is_obs = Task4CClientRobotA.PhoenixSocketClient.send_robot_status(channel_status,channel_position,robot)
          go_to_goal(robot, goal_x, goal_y, channel_status, channel_position)
        end
        %Task4CClientRobotA.Position{x: x, y: y, facing: facing} = robot
        # IO.puts("exited if")
      end

    end

    %Task4CClientRobotA.Position{x: x, y: y, facing: facing} = robot
    #call the base go_to_goal func at this point
    # go_to_goal(robot, goal_x, goal_y, channel_status, channel_position)
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

  def get_robot_b(channel) do
    {:ok, robot_b_pos} = PhoenixClient.Channel.push(channel, "give_robot_b_pos", "nil")
  end

  def dist_from_A(%Task4CClientRobotA.Position{x: x, y: y, facing: facing} = robot, goal_locs, i) do
    y_map_atom_to_int = %{:a => 1, :b => 2, :c => 3, :d => 4, :e => 5}
    y_int = y_map_atom_to_int[y]
    y_dest_int = y_map_atom_to_int[String.to_atom(Enum.at(Enum.at(goal_locs, i), 1))]
    {k, ""} = Integer.parse(Enum.at(Enum.at(goal_locs, i), 0))
    abs(k - x) + abs(y_dest_int - y_int)
  end

  def dist(%Task4CClientRobotA.Position{x: x, y: y, facing: facing} = robot,goal_locs,i,index_list,dist_list) do
    # i = 0
    index_list = index_list ++ [i]

    distance =
      dist_from_A(%Task4CClientRobotA.Position{x: x, y: y, facing: facing} = robot, goal_locs, i)

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

  def add_index(dist_list, goal_locs, i, new_list) do
    if i < Enum.count(goal_locs) do
      cell_to_insert = %SortedListStruct{value: Enum.at(dist_list, i), index: i}
      new_list = [cell_to_insert | new_list]
      i = i + 1
      add_index(dist_list, goal_locs, i, new_list)
    else
      new_list
    end
  end

  ###########################################################################################################################
  def visited_index(j, visited_index,channel_position) do
    ##function to update the visited index list
    {:ok, reply} = PhoenixClient.Channel.push(channel_position,"update_visited_index", visited_index)
    # Agent.update(:indexes, fn list -> visited_index end)
  end
  def get_posB(channel_position) do
    # Process.sleep(200)
    #fuction to get the robot B position
    {:ok,robot_b_data} = PhoenixClient.Channel.push(channel_position,"getPosB","nil")
    robot_b_data =
      if robot_b_data == "robot b pos not recived" do
        # Process.sleep(3000)
        {:ok, robot_b_data} = get_posB(channel_position)
        robot_b_data
      else
        robot_b_data
      end
    # Agent.get(:your_map_name, fn map -> Map.get(map, :robotB) end)
    {:ok,robot_b_data}
  end
  def give_A(a_data,i,channel_position) do
    # if i == 0 do
    #   {:ok, pid} = Agent.start_link(fn -> %{} end)
    #   Process.register(pid, :give_info_A)
    # end

    #function to update a_data list
    # IO.inspect(a_data)
    PhoenixClient.Channel.push(channel_position,"update_a_data",a_data)
    # Agent.update(:give_info_A, fn list -> a_data end)
  end
  ###################################################################################################################################
  defp make_int(main, i, new_list) do
    if(i >= 0) do
      new_list =
        if rem(i, 2) == 0 do
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

  defp sort_B(channel_position) do
    {:ok,string} = get_posB(channel_position)
    main = String.slice(string, 4..-1)
    main = String.split(main, "", trim: true)
    main = Enum.reject(main, fn x -> x in [","] end)
    new_list = []
    new_list = make_int(main, Enum.count(main) - 1, new_list)
    sorted_B = []
    sorted_B = add_index(new_list, new_list, 0, sorted_B)
    sorted_B = Enum.sort(sorted_B, fn x, y -> x.value < y.value end)
    # IO.inspect(sorted_B)
    sorted_B
  end
  def check_reached_list(reached_list, i, goal, bool_list) do


    if i < 0 do
      bool_list
    else if (goal == Enum.at(reached_list, i)) do
      bool_list = [1]
      bool_list
    else
      i = i - 1
      check_reached_list(reached_list, i, goal, bool_list)
    end

  end
  end
  def get_goal(robot, goal_locs, i, reached_list, channel_status, channel_position, j, visited_index) do

    if(j != Enum.count(goal_locs)) do
    # IO.inspect(i)
    index_list = []
    dist_list = []
    # %Task4CClientRobotA.Position{x: x, y: y, facing: facing} = robot
    a_data = dist(robot, goal_locs, 0, index_list, dist_list)

    visited_index(j, visited_index,channel_position)
    give_A(a_data, j,channel_position)
    j = j + 1
    b_data = sort_B(channel_position)
    # IO.puts("sort b sorted")
    # IO.puts("adata")
    # IO.inspect(a_data)
    # IO.puts("bdata")
    # IO.inspect(b_data)
    goal_index_A = Enum.at(a_data, i).index  #put 0, 1, 3 ... for next closest
    goal_value_A = Enum.at(a_data, i).value
    goal_value_B = Enum.at(b_data, i).value
    goal_index_B = Enum.at(b_data, i).index
    i = i + 1

    if (((goal_index_A == goal_index_B) and (goal_value_A > goal_value_B))) or (goal_value_A == 0) do
      get_goal(robot, goal_locs, i, reached_list, channel_status, channel_position, j, visited_index)
    else
      goal = Enum.at(goal_locs, goal_index_A)
      # IO.puts("goalB")
      # IO.inspect(goal)
      # IO.puts("reached_list")
      check_reached = check_reached_list(reached_list, Enum.count(reached_list) - 1, goal, [0])
      reached_list = reached_list ++ [goal]
      # IO.inspect(reached_list)
      if (check_reached == [1]) do
        # IO.puts("in here")
        # i = i + 1
        get_goal(robot, goal_locs, i, reached_list, channel_status, channel_position, j, visited_index)
      else
        # goal_locs = List.delete_at(goal_locs, goal_index_A)
        i = 0
        visited_index = visited_index ++ [goal_index_A]
        visited_index(j, visited_index,channel_position)

        goal_x = String.to_integer(Enum.at(goal, 0))
        goal_y = String.to_atom(Enum.at(goal, 1))
        string_of_goals = "[#{Enum.at(goal,0)}, #{Enum.at(goal, 1)}]"
        send_goal_loc(channel_position,string_of_goals)
        robot = go_to_goal(robot, goal_x, goal_y, channel_status, channel_position)
        # IO.puts("robot A")
        # IO.inspect(robot)
        get_goal(robot, goal_locs, i, reached_list, channel_status, channel_position, j, visited_index)
      end
      # get_goal(robot, goal_locs, i, reached_list, channel_status, channel_position)
    end
  else
    # IO.puts("reached here")
    # sent_alt_statuss(robot,channel_status, channel_position,true)
  end
end
def send_goal_loc(channel_position, goal_location) do
  {:ok, reply} = PhoenixClient.Channel.push(channel_position,"incoming_goal_loc_a",goal_location)
end

  def go_to_goal(%Task4CClientRobotA.Position{x: x, y: y, facing: facing} = robot, goal_x, goal_y, channel_status, channel_position) do
    if (y == goal_y) and (x == goal_x) do
      robot
      # {:ok,robot}
    else
      # IO.inspect(robot)
      is_obs = Task4CClientRobotA.PhoenixSocketClient.send_robot_status(channel_status,channel_position,robot)
      # IO.inspect(robot)
      # IO.puts("----")
      if y < goal_y do
        if (facing != :north) do
          robot = right(robot)
          #is_obs = check_for_obs(robot,channel_status, channel_position)
          # send_robot_status(robot, channel_status, channel_position)
          go_to_goal(robot, goal_x, goal_y, channel_status, channel_position)
        else
          # Task4CClientRobotA.PhoenixSocketClient.send_robot_status(channel_status,channel_position,robot)
          # Task4CClientRobotA.PhoenixSocketClient.send_robot_status(channel_status,channel_position,robot)
          if(is_obs) do
          #  IO.put("Obstacle at #{x}, #{y + 1}")
          # IO.puts("Obstacle at #{x}, #{y}, #{facing}")
          objInY_north(robot, goal_x, goal_y, channel_status, channel_position, repeat = 0)
          else
            # %Task4CClientRobotA.Position{x: x, y: y, facing: facing} = robot
            # Task4CClientRobotA.PhoenixSocketClient.send_robot_status(channel_status,channel_pos,robot)
            robot = move(robot)
            # Task4CClientRobotA.PhoenixSocketClient.send_robot_status(channel_status,channel_position,robot)
            # send_robot_status(robot, channel_status, channel_position)
            go_to_goal(robot, goal_x, goal_y, channel_status, channel_position)
          end
        end
      else if y > goal_y do
        if (facing != :south) do
          robot = right(robot)
          #is_obs = check_for_obs(robot,channel_status, channel_position)
          # send_robot_status(robot, channel_status, channel_position)
          go_to_goal(robot, goal_x, goal_y, channel_status, channel_position)
        else
          # is_obs = check_for_obs(robot,channel_status, channel_position)
          if(is_obs) do
            # IO.put("Obstacle at #{x}, #{y - 1}")
            # IO.puts("Obstacle at #{x}, #{y}, #{facing}")
            objInY_south(robot, goal_x, goal_y, channel_status, channel_position, repeat = 0)
          else
            robot = move(robot)
            go_to_goal(robot, goal_x, goal_y, channel_status, channel_position)
          end
          # send_robot_status(robot, channel_status, channel_position)
        end

      else
        if x > goal_x do
          if (facing != :west) do
            robot = right(robot)

            # send_robot_status(robot, channel_status, channel_position)
            #is_obs = check_for_obs(robot,channel_status, channel_position)
            go_to_goal(robot, goal_x, goal_y, channel_status, channel_position)
          else

            # is_obs = check_for_obs(robot,channel_status, channel_position)

            if(is_obs) do
              # IO.puts("Obstacle at #{x}, #{y}, #{facing}")
              objInX_west(robot, goal_x, goal_y, channel_status, channel_position, repeat = 0)


            else
              robot = move(robot)

              go_to_goal(robot, goal_x, goal_y, channel_status, channel_position)
            end
          end
            # send_robot_status(robot, channel_status, channel_position)

        else if x < goal_x do
          # Task4CClientRobotA.PhoenixSocketClient.send_robot_status(channel_status,channel_position,robot)

          if (facing != :east) do
            robot = right(robot)

            # send_robot_status(robot, channel_status, channel_position)
            #is_obs = check_for_obs(robot,channel_status, channel_position)
            go_to_goal(robot, goal_x, goal_y, channel_status, channel_position)

          else

            # is_obs = check_for_obs(robot,channel_status, channel_position)

            if(is_obs) do
              # IO.put("Obstacle at #{x + 1}, #{y}")
              # IO.puts("Obstacle at #{x}, #{y}, #{facing}")
              objInX_east(robot, goal_x, goal_y, channel_status, channel_position, repeat = 0)#-----



            else

              robot = move(robot)

              go_to_goal(robot, goal_x, goal_y, channel_status, channel_position)
            end
          end

            # send_robot_status(robot, channel_status, channel_position)

        else
          Task4CClientRobotA.PhoenixSocketClient.send_robot_status(channel_status,channel_position,robot)
          # {:ok,robot}

        end
       end
      end
    end       # --> end for the main if - else
  end         # --> end for the main go_to_goal function
  end

  @doc """
  Provide GOAL positions to the robot as given location of [(x1, y1),(x2, y2),..] and plan the path from START to these locations.
  Make a call to ToyRobot.PhoenixSocketClient.send_robot_status/2 to get the indication of obstacle presence ahead of the robot.
  """
  def stop(robot, goal_locs,channel_status, channel_position) do
    # get_goal(robot, goal_locs, 0, [], channel_status,channel_position, 0, [])
    goal_locs =
    if Enum.empty?(goal_locs) == false do
      goal1 = Enum.at(goal_locs,0)
      goal_x = goal1["x"]
      goal_y = String.to_atom(goal1["y"])

      IO.inspect({goal_x, goal_y})
      robot = go_to_goal(robot,goal_x,goal_y,channel_status,channel_position)
      goal_locs = List.delete_at(goal_locs,0)
      stop(robot, goal_locs, channel_status,channel_position)
    else
      goal_locs
    end
    goal_locs
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
