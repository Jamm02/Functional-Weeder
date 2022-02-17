defmodule Task4CClientRobotB do
  # max x-coordinate of table top
  @table_top_x 6
  # max y-coordinate of table top
  @table_top_y :f
  # mapping of y-coordinates
  @robot_map_y_atom_to_num %{:a => 1, :b => 2, :c => 3, :d => 4, :e => 5, :f => 6}

  @doc """
  Places the robot to the default position of (1, A, North)

  Examples:

      iex> Task4CClientRobotB.place
      {:ok, %Task4CClientRobotB.Position{facing: :north, x: 1, y: :a}}
  """
  def place do
    {:ok, %Task4CClientRobotB.Position{}}
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

      iex> Task4CClientRobotB.place(1, :b, :south)
      {:ok, %Task4CClientRobotB.Position{facing: :south, x: 1, y: :b}}

      iex> Task4CClientRobotB.place(-1, :f, :north)
      {:failure, "Invalid position"}

      iex> Task4CClientRobotB.place(3, :c, :north_east)
      {:failure, "Invalid facing direction"}
  """
  def place(x, y, facing) do
    {:ok, %Task4CClientRobotB.Position{x: x, y: y, facing: facing}}
  end

  @doc """
  Provide START position to the robot as given location of (x, y, facing) and place it.
  """
  def start(x, y, facing) do
    place(x, y, facing)
  end

  @doc """
  Main function to initiate the sequence of tasks to achieve by the Client Robot B,
  such as connect to the Phoenix server, get the robot B's start and goal locations to be traversed.
  Call the respective functions from this module and others as needed.
  You may create extra helper functions as needed.
  """
  def main do
    {:ok, _response, channel_status,channel_startPos} = Task4CClientRobotB.PhoenixSocketClient.connect_server()
    {:ok, position} = get_start_pos(channel_startPos)
    new = String.replace(position," ","")
    str = String.split(new,",")
    {x,""} = Integer.parse(Enum.at(str,0))
    y = String.to_atom(Enum.at(str,1))
    facing = String.to_atom(Enum.at(str,2))
    start(x,y,facing)
    robot_start = %Task4CClientRobotB.Position{x: x, y: y, facing: facing}
    {:ok,goal_locs} = get_goal_locs(channel_startPos)
    # IO.inspect(goal_locs)
    # IO.inspect(goal_locs)
    # IO.inspect(robot_start)
    goal_locs = Enum.reverse(goal_locs)
    goal_locs = stop(robot_start,goal_locs,channel_status,channel_startPos)
    Process.sleep(5000)
    broadcast_stop(channel_startPos)
    rob = get_correct_robot_position(channel_startPos)
  end
  def broadcast_stop(channel_position) do
    {:ok,reply} = PhoenixClient.Channel.push(channel_position,"stop_b","nil")
  end
#fucntio to get the start positions entered by the user on the server arena live
  def get_start_pos(channel) do
    {:ok, position} = PhoenixClient.Channel.push(channel, "give_start_posb", "nil")
    position =
    if position == "start pos not recived" do
      # Process.sleep(3000)
      {:ok, position} = get_start_pos(channel)
      position
    else
      position
    end
    {:ok,position}
  end
  #fucntion to get the goal location from the csv file in the server
  def get_goal_locs(channel) do
    {:ok, goal_locs} = PhoenixClient.Channel.push(channel, "give_goal_loc_b", "nil")
    goal_locs =
    if goal_locs == "goal pos not recived" do
      # Process.sleep(3000)
      {:ok, goal_locs} = get_goal_locs(channel)
      goal_locs
    else
      goal_locs
    end
    {:ok,goal_locs}
  end


  def correct_X(%Task4CClientRobotB.Position{x: x, y: y, facing: facing} = robot, goal_x, goal_y, channel_status, channel_position) do
    %Task4CClientRobotB.Position{x: x, y: y, facing: facing} = robot

    if(goal_x == x) do
      # is_obs = Task4CClientRobotB.PhoenixSocketClient.send_robot_status(channel_status, channel_position,robot)
      go_to_goal(robot, goal_x, goal_y, channel_status, channel_position)
      {:ok, robot}

    else
    is_obs = Task4CClientRobotB.PhoenixSocketClient.send_robot_status(channel_status, channel_position,robot)
    if x > goal_x do

      if (facing != :west) do
        robot = right(robot)
        %Task4CClientRobotB.Position{x: x, y: y, facing: facing} = robot
        # send_robot_status(robot, channel_status, channel_position)
        #is_obs = check_for_obs(robot,channel_status, channel_position)
        correct_X(robot, goal_x, goal_y, channel_status, channel_position)
      else
        %Task4CClientRobotB.Position{x: x, y: y, facing: facing} = robot
        # is_obs = check_for_obs(robot,channel_status, channel_position)

        if(is_obs) do
          # IO.puts("Obstacle at #{x}, #{y}, #{facing}")
          objInX_west(robot, goal_x, goal_y, channel_status, channel_position, repeat = 0)
          %Task4CClientRobotB.Position{x: x, y: y, facing: facing} = robot

        else
          robot = move(robot)
          %Task4CClientRobotB.Position{x: x, y: y, facing: facing} = robot
          correct_X(robot, goal_x, goal_y, channel_status, channel_position)
        end
      end
        # send_robot_status(robot, channel_status, channel_position)

    else if x < goal_x do
      # is_obs = Task4CClientRobotB.PhoenixSocketClient.send_robot_status(channel_status, channel_position,robot)
      %Task4CClientRobotB.Position{x: x, y: y, facing: facing} = robot

      if (facing != :east) do
        robot = right(robot)
        %Task4CClientRobotB.Position{x: x, y: y, facing: facing} = robot
        # send_robot_status(robot, channel_status, channel_position)
        #is_obs = check_for_obs(robot,channel_status, channel_position)
        correct_X(robot, goal_x, goal_y, channel_status, channel_position)

      else
        %Task4CClientRobotB.Position{x: x, y: y, facing: facing} = robot
        # is_obs = check_for_obs(robot,channel_status, channel_position)

        if(is_obs) do
          # IO.put("Obstacle at #{x + 1}, #{y}")
          # IO.puts("Obstacle at #{x}, #{y}, #{facing}")
          objInX_east(robot, goal_x, goal_y, channel_status, channel_position, repeat = 0)
          %Task4CClientRobotB.Position{x: x, y: y, facing: facing} = robot


        else
          robot = move(robot)
          %Task4CClientRobotB.Position{x: x, y: y, facing: facing} = robot
          correct_X(robot, goal_x, goal_y, channel_status, channel_position)
        end
      end
    end
  end
end
end
  def objInY_north(%Task4CClientRobotB.Position{x: x, y: y, facing: facing} = robot, goal_x, goal_y, channel_status, channel_position, repeat) do
    %Task4CClientRobotB.Position{x: x, y: y, facing: facing} = robot

    # make sure bot is facing north
    # IO.puts("in north")
    if (x == 1) or (repeat == 1)  do  #turn and right and face north
      # IO.puts("in 1")
      robot = right(robot);
      %Task4CClientRobotB.Position{x: x, y: y, facing: facing} = robot
      is_obs = Task4CClientRobotB.PhoenixSocketClient.send_robot_status(channel_status, channel_position,robot)

      if(is_obs) do
        robot = right(robot)
        %Task4CClientRobotB.Position{x: x, y: y, facing: facing} = robot
        is_obs = Task4CClientRobotB.PhoenixSocketClient.send_robot_status(channel_status, channel_position,robot)
        robot = move(robot)
        %Task4CClientRobotB.Position{x: x, y: y, facing: facing} = robot
        is_obs = Task4CClientRobotB.PhoenixSocketClient.send_robot_status(channel_status, channel_position,robot)
        robot = left(robot)
        %Task4CClientRobotB.Position{x: x, y: y, facing: facing} = robot
        is_obs = Task4CClientRobotB.PhoenixSocketClient.send_robot_status(channel_status, channel_position,robot)

        if(is_obs) do
          objInX_east(%Task4CClientRobotB.Position{x: x, y: y, facing: facing} = robot, goal_x, goal_y, channel_status, channel_position, repeat = 0)
        else
          robot = move(robot)
          %Task4CClientRobotB.Position{x: x, y: y, facing: facing} = robot
          # is_obs = Task4CClientRobotB.PhoenixSocketClient.send_robot_status(channel_status, channel_position,robot)
          go_to_goal(robot, goal_x, goal_y, channel_status, channel_position)
        end
        %Task4CClientRobotB.Position{x: x, y: y, facing: facing} = robot

      else
        robot = move(robot);
        %Task4CClientRobotB.Position{x: x, y: y, facing: facing} = robot
        is_obs = Task4CClientRobotB.PhoenixSocketClient.send_robot_status(channel_status, channel_position,robot)
        robot = left(robot);
        is_obs = Task4CClientRobotB.PhoenixSocketClient.send_robot_status(channel_status, channel_position,robot)
        %Task4CClientRobotB.Position{x: x, y: y, facing: facing} = robot
        if (is_obs) do
          repeat = 1
          objInY_north(robot, goal_x, goal_y, channel_status, channel_position, repeat)
        else
          robot = move(robot)
          %Task4CClientRobotB.Position{x: x, y: y, facing: facing} = robot
          #is_obs = Task4CClientRobotB.PhoenixSocketClient.send_robot_status(channel_status, channel_position,robot)
          if (x != goal_x) do
            correct_X(robot, goal_x, goal_y, channel_status, channel_position)
          else
            go_to_goal(robot, goal_x, goal_y, channel_status, channel_position)
          end
        end
        %Task4CClientRobotB.Position{x: x, y: y, facing: facing} = robot

        # IO.puts("exited if")
      end

    else #turn and move left and face north
      # IO.puts("in 2")
      robot = left(robot);
      %Task4CClientRobotB.Position{x: x, y: y, facing: facing} = robot
      is_obs = Task4CClientRobotB.PhoenixSocketClient.send_robot_status(channel_status, channel_position,robot)

      if(is_obs) do
        robot = left(robot)
        %Task4CClientRobotB.Position{x: x, y: y, facing: facing} = robot
        is_obs = Task4CClientRobotB.PhoenixSocketClient.send_robot_status(channel_status, channel_position,robot)
        robot = move(robot)
        %Task4CClientRobotB.Position{x: x, y: y, facing: facing} = robot
        is_obs = Task4CClientRobotB.PhoenixSocketClient.send_robot_status(channel_status, channel_position,robot)
        robot = right(robot)
        %Task4CClientRobotB.Position{x: x, y: y, facing: facing} = robot
        is_obs = Task4CClientRobotB.PhoenixSocketClient.send_robot_status(channel_status, channel_position,robot)

        if(is_obs) do
          objInX_west(%Task4CClientRobotB.Position{x: x, y: y, facing: facing} = robot, goal_x, goal_y, channel_status, channel_position, repeat = 0)
        else
          robot = move(robot)
          %Task4CClientRobotB.Position{x: x, y: y, facing: facing} = robot
          # is_obs = Task4CClientRobotB.PhoenixSocketClient.send_robot_status(channel_status, channel_position,robot)
          go_to_goal(robot, goal_x, goal_y, channel_status, channel_position)
        end
        %Task4CClientRobotB.Position{x: x, y: y, facing: facing} = robot

      else
        robot = move(robot);
        %Task4CClientRobotB.Position{x: x, y: y, facing: facing} = robot
        is_obs = Task4CClientRobotB.PhoenixSocketClient.send_robot_status(channel_status, channel_position,robot)
        robot = right(robot);
        %Task4CClientRobotB.Position{x: x, y: y, facing: facing} = robot
        is_obs = Task4CClientRobotB.PhoenixSocketClient.send_robot_status(channel_status, channel_position,robot)
        if (is_obs) do
          repeat = 0
          objInY_north(robot, goal_x, goal_y, channel_status, channel_position, repeat)
        else
          robot = move(robot)
          # is_obs = Task4CClientRobotB.PhoenixSocketClient.send_robot_status(channel_status, channel_position,robot)
          %Task4CClientRobotB.Position{x: x, y: y, facing: facing} = robot
          if (x != goal_x) do
            correct_X(robot, goal_x, goal_y, channel_status, channel_position)
          else
            go_to_goal(robot, goal_x, goal_y, channel_status, channel_position)
          end
        end
        %Task4CClientRobotB.Position{x: x, y: y, facing: facing} = robot
        # IO.puts("exited else")
      end

    end

    %Task4CClientRobotB.Position{x: x, y: y, facing: facing} = robot
    # IO.puts("#{x}, #{y}, #{facing}")
    #call the base go_to_goal func at this point

  end
  def objInY_south(%Task4CClientRobotB.Position{x: x, y: y, facing: facing} = robot, goal_x, goal_y, channel_status, channel_position, repeat) do

    # make sure bot is facing south
    # IO.puts("in south")

    %Task4CClientRobotB.Position{x: x, y: y, facing: facing} = robot
    if (x == 1) or (repeat == 1) do  #turn, move left and face south
      robot = left(robot);
      %Task4CClientRobotB.Position{x: x, y: y, facing: facing} = robot
      is_obs = Task4CClientRobotB.PhoenixSocketClient.send_robot_status(channel_status, channel_position,robot)

      if(is_obs) do
        robot = left(robot)
        %Task4CClientRobotB.Position{x: x, y: y, facing: facing} = robot
        is_obs = Task4CClientRobotB.PhoenixSocketClient.send_robot_status(channel_status, channel_position,robot)
        robot = move(robot)
        %Task4CClientRobotB.Position{x: x, y: y, facing: facing} = robot
        is_obs = Task4CClientRobotB.PhoenixSocketClient.send_robot_status(channel_status, channel_position,robot)
        robot = right(robot)
        %Task4CClientRobotB.Position{x: x, y: y, facing: facing} = robot
        is_obs = Task4CClientRobotB.PhoenixSocketClient.send_robot_status(channel_status, channel_position,robot)

        if(is_obs) do
          objInX_east(%Task4CClientRobotB.Position{x: x, y: y, facing: facing} = robot, goal_x, goal_y, channel_status, channel_position, repeat = 0)
        else
          robot = move(robot)
          %Task4CClientRobotB.Position{x: x, y: y, facing: facing} = robot
          # is_obs = Task4CClientRobotB.PhoenixSocketClient.send_robot_status(channel_status, channel_position,robot)
          go_to_goal(robot, goal_x, goal_y, channel_status, channel_position)

        end
        %Task4CClientRobotB.Position{x: x, y: y, facing: facing} = robot

      else
        robot = move(robot);
        %Task4CClientRobotB.Position{x: x, y: y, facing: facing} = robot
        is_obs = Task4CClientRobotB.PhoenixSocketClient.send_robot_status(channel_status, channel_position,robot)
        robot = right(robot);
        %Task4CClientRobotB.Position{x: x, y: y, facing: facing} = robot
        is_obs = Task4CClientRobotB.PhoenixSocketClient.send_robot_status(channel_status, channel_position,robot)
        if (is_obs) do
          repeat = 1
          objInY_south(robot, goal_x, goal_y, channel_status, channel_position, repeat)
        else
          robot = move(robot)
          %Task4CClientRobotB.Position{x: x, y: y, facing: facing} = robot
          # is_obs = Task4CClientRobotB.PhoenixSocketClient.send_robot_status(channel_status, channel_position,robot)
          if (x != goal_x) do
            correct_X(robot, goal_x, goal_y, channel_status, channel_position)
          else
            go_to_goal(robot, goal_x, goal_y, channel_status, channel_position)
          end
        end
        %Task4CClientRobotB.Position{x: x, y: y, facing: facing} = robot
        # IO.puts("exited else")
      end

    else #turn, move right and go south
      robot = right(robot);
      %Task4CClientRobotB.Position{x: x, y: y, facing: facing} = robot
      is_obs = Task4CClientRobotB.PhoenixSocketClient.send_robot_status(channel_status, channel_position,robot)

      if(is_obs) do
        robot = right(robot)
        %Task4CClientRobotB.Position{x: x, y: y, facing: facing} = robot
        is_obs = Task4CClientRobotB.PhoenixSocketClient.send_robot_status(channel_status, channel_position,robot)
        robot = move(robot)
        %Task4CClientRobotB.Position{x: x, y: y, facing: facing} = robot
        is_obs = Task4CClientRobotB.PhoenixSocketClient.send_robot_status(channel_status, channel_position,robot)
        robot = left(robot)
        %Task4CClientRobotB.Position{x: x, y: y, facing: facing} = robot
        is_obs = Task4CClientRobotB.PhoenixSocketClient.send_robot_status(channel_status, channel_position,robot)

        if(is_obs) do
          objInX_west(%Task4CClientRobotB.Position{x: x, y: y, facing: facing} = robot, goal_x, goal_y, channel_status, channel_position, repeat = 0)
        else
          robot = move(robot)
          %Task4CClientRobotB.Position{x: x, y: y, facing: facing} = robot
          # is_obs = Task4CClientRobotB.PhoenixSocketClient.send_robot_status(channel_status, channel_position,robot)
          go_to_goal(robot, goal_x, goal_y, channel_status, channel_position)
        end
        %Task4CClientRobotB.Position{x: x, y: y, facing: facing} = robot

      else
        robot = move(robot);
        %Task4CClientRobotB.Position{x: x, y: y, facing: facing} = robot
        is_obs = Task4CClientRobotB.PhoenixSocketClient.send_robot_status(channel_status, channel_position,robot)
        robot = left(robot);
        is_obs = Task4CClientRobotB.PhoenixSocketClient.send_robot_status(channel_status, channel_position,robot)
        %Task4CClientRobotB.Position{x: x, y: y, facing: facing} = robot
        if (is_obs) do
          repeat = 0
          objInY_south(robot, goal_x, goal_y, channel_status, channel_position, repeat)
        else
          robot = move(robot)
          %Task4CClientRobotB.Position{x: x, y: y, facing: facing} = robot
          # is_obs = Task4CClientRobotB.PhoenixSocketClient.send_robot_status(channel_status, channel_position,robot)
          if (x != goal_x) do
            correct_X(robot, goal_x, goal_y, channel_status, channel_position)
          else
            go_to_goal(robot, goal_x, goal_y, channel_status, channel_position)
          end
        end
        %Task4CClientRobotB.Position{x: x, y: y, facing: facing} = robot
        # IO.puts("exited if")
      end


    end
    %Task4CClientRobotB.Position{x: x, y: y, facing: facing} = robot
    #call the base go_to_goal func at this point
    # go_to_goal(robot, goal_x, goal_y, channel_status, channel_position)
  end
  def objInX_west(%Task4CClientRobotB.Position{x: x, y: y, facing: facing} = robot, goal_x, goal_y, channel_status, channel_position, repeat) do

    # make sure bot is facing west before running this func
    # IO.puts("in west")

    %Task4CClientRobotB.Position{x: x, y: y, facing: facing} = robot

    if (y == :a) or (repeat == 1) do  #turn, move left and face east
      robot = right(robot);
      %Task4CClientRobotB.Position{x: x, y: y, facing: facing} = robot
      is_obs = Task4CClientRobotB.PhoenixSocketClient.send_robot_status(channel_status, channel_position,robot)


      if(is_obs) do
        robot = right(robot)
        %Task4CClientRobotB.Position{x: x, y: y, facing: facing} = robot
        is_obs = Task4CClientRobotB.PhoenixSocketClient.send_robot_status(channel_status, channel_position,robot)
        robot = move(robot)
        %Task4CClientRobotB.Position{x: x, y: y, facing: facing} = robot
        is_obs = Task4CClientRobotB.PhoenixSocketClient.send_robot_status(channel_status, channel_position,robot)
        robot = left(robot)
        %Task4CClientRobotB.Position{x: x, y: y, facing: facing} = robot
        is_obs = Task4CClientRobotB.PhoenixSocketClient.send_robot_status(channel_status, channel_position,robot)

        if(is_obs) do
          objInY_north(%Task4CClientRobotB.Position{x: x, y: y, facing: facing} = robot, goal_x, goal_y, channel_status, channel_position, repeat = 0)
        else
          robot = move(robot)
          %Task4CClientRobotB.Position{x: x, y: y, facing: facing} = robot
          # is_obs = Task4CClientRobotB.PhoenixSocketClient.send_robot_status(channel_status, channel_position,robot)
          correct_X(robot, goal_x, goal_y, channel_status, channel_position)
        end
        %Task4CClientRobotB.Position{x: x, y: y, facing: facing} = robot

      else
        robot = move(robot);
        %Task4CClientRobotB.Position{x: x, y: y, facing: facing} = robot
        is_obs = Task4CClientRobotB.PhoenixSocketClient.send_robot_status(channel_status, channel_position,robot)
        robot = left(robot);
        is_obs = Task4CClientRobotB.PhoenixSocketClient.send_robot_status(channel_status, channel_position,robot)
        %Task4CClientRobotB.Position{x: x, y: y, facing: facing} = robot
        if (is_obs) do
          repeat = 1
          objInX_west(robot, goal_x, goal_y, channel_status, channel_position, repeat)
        else
          robot = move(robot)
          # is_obs = Task4CClientRobotB.PhoenixSocketClient.send_robot_status(channel_status, channel_position,robot)
          %Task4CClientRobotB.Position{x: x, y: y, facing: facing} = robot
          go_to_goal(robot, goal_x, goal_y, channel_status, channel_position)
        end
        %Task4CClientRobotB.Position{x: x, y: y, facing: facing} = robot
        # IO.puts("exited if")
      end


    else #turn, move right and go south

      robot = left(robot);
      %Task4CClientRobotB.Position{x: x, y: y, facing: facing} = robot
      is_obs = Task4CClientRobotB.PhoenixSocketClient.send_robot_status(channel_status, channel_position,robot)


      if(is_obs) do
        robot = left(robot)
        %Task4CClientRobotB.Position{x: x, y: y, facing: facing} = robot
        is_obs = Task4CClientRobotB.PhoenixSocketClient.send_robot_status(channel_status, channel_position,robot)
        robot = move(robot)
        %Task4CClientRobotB.Position{x: x, y: y, facing: facing} = robot
        is_obs = Task4CClientRobotB.PhoenixSocketClient.send_robot_status(channel_status, channel_position,robot)
        robot = right(robot)
        %Task4CClientRobotB.Position{x: x, y: y, facing: facing} = robot
        is_obs = Task4CClientRobotB.PhoenixSocketClient.send_robot_status(channel_status, channel_position,robot)

        if(is_obs) do
          objInY_south(%Task4CClientRobotB.Position{x: x, y: y, facing: facing} = robot, goal_x, goal_y, channel_status, channel_position, repeat = 0)
        else
          robot = move(robot)
          %Task4CClientRobotB.Position{x: x, y: y, facing: facing} = robot
          # is_obs = Task4CClientRobotB.PhoenixSocketClient.send_robot_status(channel_status, channel_position,robot)
          correct_X(robot, goal_x, goal_y, channel_status, channel_position)
        end
        %Task4CClientRobotB.Position{x: x, y: y, facing: facing} = robot

      else
        robot = move(robot);
        %Task4CClientRobotB.Position{x: x, y: y, facing: facing} = robot
        is_obs = Task4CClientRobotB.PhoenixSocketClient.send_robot_status(channel_status, channel_position,robot)
        robot = right(robot);
        %Task4CClientRobotB.Position{x: x, y: y, facing: facing} = robot
        is_obs = Task4CClientRobotB.PhoenixSocketClient.send_robot_status(channel_status, channel_position,robot)
        if (is_obs) do
          repeat = 0
          objInX_west(robot, goal_x, goal_y, channel_status, channel_position, repeat)
        else
          robot = move(robot)
          %Task4CClientRobotB.Position{x: x, y: y, facing: facing} = robot
          # is_obs = Task4CClientRobotB.PhoenixSocketClient.send_robot_status(channel_status, channel_position,robot)
          # IO.inspect(robot)
          go_to_goal(robot, goal_x, goal_y, channel_status, channel_position)
        end
        %Task4CClientRobotB.Position{x: x, y: y, facing: facing} = robot
        # IO.puts("exited else")
      end

    end
    %Task4CClientRobotB.Position{x: x, y: y, facing: facing} = robot
    #call the base go_to_goal func at this point
    # go_to_goal(robot, goal_x, goal_y, channel_status, channel_position)
  end
  def objInX_east(%Task4CClientRobotB.Position{x: x, y: y, facing: facing} = robot, goal_x, goal_y, channel_status, channel_position, repeat) do

    # make sure bot is facing east before running this func
    # IO.puts("in east")

    %Task4CClientRobotB.Position{x: x, y: y, facing: facing} = robot

    if (y == :a) or (repeat == 1) do  #turn, move left and face west
                  #boundry case
      # IO.puts("in y=a")
      robot = left(robot)
      %Task4CClientRobotB.Position{x: x, y: y, facing: facing} = robot
      is_obs = Task4CClientRobotB.PhoenixSocketClient.send_robot_status(channel_status, channel_position,robot)

      if(is_obs) do
        robot = left(robot)
        %Task4CClientRobotB.Position{x: x, y: y, facing: facing} = robot
        is_obs = Task4CClientRobotB.PhoenixSocketClient.send_robot_status(channel_status, channel_position,robot)
        robot = move(robot)
        %Task4CClientRobotB.Position{x: x, y: y, facing: facing} = robot
        is_obs = Task4CClientRobotB.PhoenixSocketClient.send_robot_status(channel_status, channel_position,robot)
        robot = right(robot)
        %Task4CClientRobotB.Position{x: x, y: y, facing: facing} = robot
        is_obs = Task4CClientRobotB.PhoenixSocketClient.send_robot_status(channel_status, channel_position,robot)

        if(is_obs) do
          objInY_north(%Task4CClientRobotB.Position{x: x, y: y, facing: facing} = robot, goal_x, goal_y, channel_status, channel_position, repeat = 0)
        else
          robot = move(robot)
          %Task4CClientRobotB.Position{x: x, y: y, facing: facing} = robot
          # is_obs = Task4CClientRobotB.PhoenixSocketClient.send_robot_status(channel_status, channel_position,robot)
          correct_X(robot, goal_x, goal_y, channel_status, channel_position)
        end
        %Task4CClientRobotB.Position{x: x, y: y, facing: facing} = robot

      else
        robot = move(robot);
        %Task4CClientRobotB.Position{x: x, y: y, facing: facing} = robot
        is_obs = Task4CClientRobotB.PhoenixSocketClient.send_robot_status(channel_status, channel_position,robot)
        robot = right(robot);
        %Task4CClientRobotB.Position{x: x, y: y, facing: facing} = robot
        is_obs = Task4CClientRobotB.PhoenixSocketClient.send_robot_status(channel_status, channel_position,robot)
        if (is_obs) do
          repeat = 1
          objInX_east(robot, goal_x, goal_y, channel_status, channel_position, repeat)
        else
          robot = move(robot)
          %Task4CClientRobotB.Position{x: x, y: y, facing: facing} = robot
          go_to_goal(robot, goal_x, goal_y, channel_status, channel_position)
        end
        %Task4CClientRobotB.Position{x: x, y: y, facing: facing} = robot

        #is_obs = Task4CClientRobotB.PhoenixSocketClient.send_robot_status(channel_status, channel_position,robot)
        # IO.puts("exited else")
      end

    else #turn, move right and face east//
      # IO.puts("in else")
      robot = left(robot);#########################
      %Task4CClientRobotB.Position{x: x, y: y, facing: facing} = robot
      is_obs = Task4CClientRobotB.PhoenixSocketClient.send_robot_status(channel_status, channel_position,robot)

      if(is_obs) do
        # IO.puts("in isobs")
        robot = right(robot)
        %Task4CClientRobotB.Position{x: x, y: y, facing: facing} = robot
        is_obs = Task4CClientRobotB.PhoenixSocketClient.send_robot_status(channel_status, channel_position,robot)

        robot = move(robot)
        %Task4CClientRobotB.Position{x: x, y: y, facing: facing} = robot
        is_obs = Task4CClientRobotB.PhoenixSocketClient.send_robot_status(channel_status, channel_position,robot)

        robot = left(robot)
        %Task4CClientRobotB.Position{x: x, y: y, facing: facing} = robot
        is_obs = Task4CClientRobotB.PhoenixSocketClient.send_robot_status(channel_status, channel_position,robot)

        if(is_obs) do
          objInY_south(%Task4CClientRobotB.Position{x: x, y: y, facing: facing} = robot, goal_x, goal_y, channel_status, channel_position, repeat = 0)
        else
          robot = move(robot)
          %Task4CClientRobotB.Position{x: x, y: y, facing: facing} = robot
          # is_obs = Task4CClientRobotB.PhoenixSocketClient.send_robot_status(channel_status, channel_position,robot)
          correct_X(robot, goal_x, goal_y, channel_status, channel_position)
        end
        %Task4CClientRobotB.Position{x: x, y: y, facing: facing} = robot

      else
        # IO.puts("in else isobs")
        robot = move(robot);
        %Task4CClientRobotB.Position{x: x, y: y, facing: facing} = robot
        is_obs = Task4CClientRobotB.PhoenixSocketClient.send_robot_status(channel_status, channel_position,robot)
        robot = right(robot);##################
        is_obs = Task4CClientRobotB.PhoenixSocketClient.send_robot_status(channel_status, channel_position,robot)
        %Task4CClientRobotB.Position{x: x, y: y, facing: facing} = robot

        if (is_obs) do
          # IO.puts("in unwanted")
          repeat = 0
          objInX_east(robot, goal_x, goal_y, channel_status, channel_position, repeat)
        else
          # IO.puts("in wanted")
          robot = move(robot)
          %Task4CClientRobotB.Position{x: x, y: y, facing: facing} = robot
          # is_obs = Task4CClientRobotB.PhoenixSocketClient.send_robot_status(channel_status, channel_position,robot)
          go_to_goal(robot, goal_x, goal_y, channel_status, channel_position)
        end
        %Task4CClientRobotB.Position{x: x, y: y, facing: facing} = robot
        # IO.puts("exited if")
      end

    end

    %Task4CClientRobotB.Position{x: x, y: y, facing: facing} = robot
    #call the base go_to_goal func at this point
    # go_to_goal(robot, goal_x, goal_y, channel_status, channel_position)
  end

  @doc """
  Provide GOAL positions to the robot as given location of [(x1, y1),(x2, y2),..] and plan the path from START to these locations.
  Make a call to ToyRobot.PhoenixSocketClient.send_robot_status/2 to get the indication of obstacle presence ahead of the robot.
  """
  def stop(robot, goal_locs,channel_status, channel_position) do
    goal_locs =
      if Enum.empty?(goal_locs) == false do
        goal1 = Enum.at(goal_locs,0)
        # goal_x = goal1["x"]
        # goal_y = String.to_atom(goal1["y"])
        goal_x = String.to_integer(Enum.at(goal1,0))
        goal_y = String.to_atom(Enum.at(goal1,1))
        # IO.inspect({goal_x, goal_y})
        robot_old = go_to_goal(robot,goal_x,goal_y,channel_status,channel_position)
        # IO.inspect(robot)
        robot_corr = get_correct_robot_position(channel_position)
        # IO.inspect(robot_corr)
        robot = %Task4CClientRobotB.Position{x: robot_corr["x"], y: String.to_atom(robot_corr["y"]), facing: String.to_atom(robot_corr["face"])}
        goal_locs = List.delete_at(goal_locs,0)
        stop(robot, goal_locs, channel_status,channel_position)
      else
        goal_locs
      end
      goal_locs
  end
  def get_correct_robot_position(channel_position) do
    {:ok, robot_position} = PhoenixClient.Channel.push(channel_position,"give_robb_pos","nil")
    robot_position
  end
  def go_to_goal(%Task4CClientRobotB.Position{x: x, y: y, facing: facing} = robot, goal_x, goal_y, channel_status, channel_position) do

    if (y == goal_y) and (x == goal_x) do
      is_obs = Task4CClientRobotB.PhoenixSocketClient.send_robot_status(channel_status, channel_position,robot)
      # IO.puts("go to goal b")
      # IO.inspect(robot)
      robot
      # {:ok,robot}

    else
      is_obs = Task4CClientRobotB.PhoenixSocketClient.send_robot_status(channel_status, channel_position,robot)
      # IO.inspect(robot)
      # IO.puts("----")
      if y < goal_y do
        if (facing != :north) do
          robot = right(robot)
          #is_obs = check_for_obs(robot,channel_status, channel_position)
          # send_robot_status(robot, channel_status, channel_position)
          go_to_goal(robot, goal_x, goal_y, channel_status, channel_position)
        else
          # is_obs = Task4CClientRobotB.PhoenixSocketClient.send_robot_status(channel_status, channel_position,robot)
          # is_obs = Task4CClientRobotB.PhoenixSocketClient.send_robot_status(channel_status, channel_position,robot)
          if(is_obs) do
          #  IO.put("Obstacle at #{x}, #{y + 1}")
          # IO.puts("Obstacle at #{x}, #{y}, #{facing}")
           objInY_north(robot, goal_x, goal_y, channel_status, channel_position, repeat = 0)
          else
            # %Task4CClientRobotB.Position{x: x, y: y, facing: facing} = robot
            # is_obs = Task4CClientRobotB.PhoenixSocketClient.send_robot_status(channel_status, channel_position,robot)
            robot = move(robot)
            # is_obs = Task4CClientRobotB.PhoenixSocketClient.send_robot_status(channel_status, channel_position,robot)
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
          # is_obs = Task4CClientRobotB.PhoenixSocketClient.send_robot_status(channel_status, channel_position,robot)
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
          is_obs = Task4CClientRobotB.PhoenixSocketClient.send_robot_status(channel_status, channel_position,robot)
          # {:ok,robot}
        end
       end
      end
    end       # --> end for the main if - else
  end         # --> end for the main go_to_goal function

  end

def send_goal_loc(channel_position, goal_location) do
  {:ok, reply} = PhoenixClient.Channel.push(channel_position,"incoming_goal_loc_b",goal_location)
end
  @doc """
  Provides the report of the robot's current position

  Examples:

      iex> {:ok, robot} = Task4CClientRobotB.place(2, :b, :west)
      iex> Task4CClientRobotB.report(robot)
      {2, :b, :west}
  """
  def report(%Task4CClientRobotB.Position{x: x, y: y, facing: facing} = _robot) do
    {x, y, facing}
  end

  @directions_to_the_right %{north: :east, east: :south, south: :west, west: :north}
  @doc """
  Rotates the robot to the right
  """
  def right(%Task4CClientRobotB.Position{facing: facing} = robot) do
    %Task4CClientRobotB.Position{robot | facing: @directions_to_the_right[facing]}
  end

  @directions_to_the_left Enum.map(@directions_to_the_right, fn {from, to} -> {to, from} end)
  @doc """
  Rotates the robot to the left
  """
  def left(%Task4CClientRobotB.Position{facing: facing} = robot) do
    %Task4CClientRobotB.Position{robot | facing: @directions_to_the_left[facing]}
  end

  @doc """
  Moves the robot to the north, but prevents it to fall
  """
  def move(%Task4CClientRobotB.Position{x: _, y: y, facing: :north} = robot) when y < @table_top_y do
    %Task4CClientRobotB.Position{ robot | y: Enum.find(@robot_map_y_atom_to_num, fn {_, val} -> val == Map.get(@robot_map_y_atom_to_num, y) + 1 end) |> elem(0)
    }
  end

  @doc """
  Moves the robot to the east, but prevents it to fall
  """
  def move(%Task4CClientRobotB.Position{x: x, y: _, facing: :east} = robot) when x < @table_top_x do
    %Task4CClientRobotB.Position{robot | x: x + 1}
  end

  @doc """
  Moves the robot to the south, but prevents it to fall
  """
  def move(%Task4CClientRobotB.Position{x: _, y: y, facing: :south} = robot) when y > :a do
    %Task4CClientRobotB.Position{ robot | y: Enum.find(@robot_map_y_atom_to_num, fn {_, val} -> val == Map.get(@robot_map_y_atom_to_num, y) - 1 end) |> elem(0)}
  end

  @doc """
  Moves the robot to the west, but prevents it to fall
  """
  def move(%Task4CClientRobotB.Position{x: x, y: _, facing: :west} = robot) when x > 1 do
    %Task4CClientRobotB.Position{robot | x: x - 1}
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
