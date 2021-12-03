defmodule ToyRobot do
  # max x-coordinate of table top
  @table_top_x 5
  # max y-coordinate of table top
  @table_top_y :e
  # mapping of y-coordinates
  @robot_map_y_atom_to_num %{:a => 1, :b => 2, :c => 3, :d => 4, :e => 5}

  @doc """
  Places the robot to the default position of (1, A, North)

  Examples:

      iex> ToyRobot.place
      {:ok, %ToyRobot.Position{facing: :north, x: 1, y: :a}}
  """
  def place do
    {:ok, %ToyRobot.Position{}}
  end

  def place(x, y, _facing) when x < 1 or y < :a or x > @table_top_x or y > @table_top_y do
    {:failure, "Invalid position"}
  end

  def place(_x, _y, facing)
  when facing not in [:north, :east, :south, :west]
  do
    {:failure, "Invalid facing direction"}
  end

  def correct_X(%ToyRobot.Position{x: x, y: y, facing: facing} = robot, goal_x, goal_y, channel) do
    %ToyRobot.Position{x: x, y: y, facing: facing} = robot

    if(goal_x == x) do
      # is_obs = ToyRobot.PhoenixSocketClient.send_robot_status(channel, robot)
      stop(robot, goal_x, goal_y, channel)
      {:ok, robot}

    else
    is_obs = ToyRobot.PhoenixSocketClient.send_robot_status(channel, robot)
    if x > goal_x do

      if (facing != :west) do
        robot = right(robot)
        %ToyRobot.Position{x: x, y: y, facing: facing} = robot
        # send_robot_status(robot, channel)
        #is_obs = check_for_obs(robot,channel)
        correct_X(robot, goal_x, goal_y, channel)
      else
        %ToyRobot.Position{x: x, y: y, facing: facing} = robot
        # is_obs = check_for_obs(robot,channel)

        if(is_obs) do
          # IO.puts("Obstacle at #{x}, #{y}, #{facing}")
          objInX_west(robot, goal_x, goal_y, channel, repeat = 0)
          %ToyRobot.Position{x: x, y: y, facing: facing} = robot

        else
          robot = move(robot)
          %ToyRobot.Position{x: x, y: y, facing: facing} = robot
          correct_X(robot, goal_x, goal_y, channel)
        end
      end
        # send_robot_status(robot, channel)

    else if x < goal_x do
      # is_obs = ToyRobot.PhoenixSocketClient.send_robot_status(channel, robot)
      %ToyRobot.Position{x: x, y: y, facing: facing} = robot

      if (facing != :east) do
        robot = right(robot)
        %ToyRobot.Position{x: x, y: y, facing: facing} = robot
        # send_robot_status(robot, channel)
        #is_obs = check_for_obs(robot,channel)
        correct_X(robot, goal_x, goal_y, channel)

      else
        %ToyRobot.Position{x: x, y: y, facing: facing} = robot
        # is_obs = check_for_obs(robot,channel)

        if(is_obs) do
          # IO.put("Obstacle at #{x + 1}, #{y}")
          # IO.puts("Obstacle at #{x}, #{y}, #{facing}")
          objInX_east(robot, goal_x, goal_y, channel, repeat = 0)
          %ToyRobot.Position{x: x, y: y, facing: facing} = robot


        else
          robot = move(robot)
          %ToyRobot.Position{x: x, y: y, facing: facing} = robot
          correct_X(robot, goal_x, goal_y, channel)
        end
      end
    end
  end
end
end



def objInY_north(%ToyRobot.Position{x: x, y: y, facing: facing} = robot, goal_x, goal_y, channel, repeat) do
  %ToyRobot.Position{x: x, y: y, facing: facing} = robot

  # make sure bot is facing north
  # IO.puts("in north")
  if (x == 1) or (repeat == 1)  do  #turn and right and face north
    # IO.puts("in 1")
    robot = right(robot);
    %ToyRobot.Position{x: x, y: y, facing: facing} = robot
    is_obs = ToyRobot.PhoenixSocketClient.send_robot_status(channel, robot)

    if(is_obs) do
      robot = right(robot)
      %ToyRobot.Position{x: x, y: y, facing: facing} = robot
      is_obs = ToyRobot.PhoenixSocketClient.send_robot_status(channel, robot)
      robot = move(robot)
      %ToyRobot.Position{x: x, y: y, facing: facing} = robot
      is_obs = ToyRobot.PhoenixSocketClient.send_robot_status(channel, robot)
      robot = left(robot)
      %ToyRobot.Position{x: x, y: y, facing: facing} = robot
      is_obs = ToyRobot.PhoenixSocketClient.send_robot_status(channel, robot)

      if(is_obs) do
        objInX_east(%ToyRobot.Position{x: x, y: y, facing: facing} = robot, goal_x, goal_y, channel, repeat = 0)
      else
        robot = move(robot)
        %ToyRobot.Position{x: x, y: y, facing: facing} = robot
        # is_obs = ToyRobot.PhoenixSocketClient.send_robot_status(channel, robot)
        stop(robot, goal_x, goal_y, channel)
      end
      %ToyRobot.Position{x: x, y: y, facing: facing} = robot

    else
      robot = move(robot);
      %ToyRobot.Position{x: x, y: y, facing: facing} = robot
      is_obs = ToyRobot.PhoenixSocketClient.send_robot_status(channel, robot)
      robot = left(robot);
      is_obs = ToyRobot.PhoenixSocketClient.send_robot_status(channel, robot)
      %ToyRobot.Position{x: x, y: y, facing: facing} = robot
      if (is_obs) do
        repeat = 1
        objInY_north(robot, goal_x, goal_y, channel, repeat)
      else
        robot = move(robot)
        %ToyRobot.Position{x: x, y: y, facing: facing} = robot
        #is_obs = ToyRobot.PhoenixSocketClient.send_robot_status(channel, robot)
        if (x != goal_x) do
          correct_X(robot, goal_x, goal_y, channel)
        else
          stop(robot, goal_x, goal_y, channel)
        end
      end
      %ToyRobot.Position{x: x, y: y, facing: facing} = robot

      # IO.puts("exited if")
    end

  else #turn and move left and face north
    # IO.puts("in 2")
    robot = left(robot);
    %ToyRobot.Position{x: x, y: y, facing: facing} = robot
    is_obs = ToyRobot.PhoenixSocketClient.send_robot_status(channel, robot)

    if(is_obs) do
      robot = left(robot)
      %ToyRobot.Position{x: x, y: y, facing: facing} = robot
      is_obs = ToyRobot.PhoenixSocketClient.send_robot_status(channel, robot)
      robot = move(robot)
      %ToyRobot.Position{x: x, y: y, facing: facing} = robot
      is_obs = ToyRobot.PhoenixSocketClient.send_robot_status(channel, robot)
      robot = right(robot)
      %ToyRobot.Position{x: x, y: y, facing: facing} = robot
      is_obs = ToyRobot.PhoenixSocketClient.send_robot_status(channel, robot)

      if(is_obs) do
        objInX_west(%ToyRobot.Position{x: x, y: y, facing: facing} = robot, goal_x, goal_y, channel, repeat = 0)
      else
        robot = move(robot)
        %ToyRobot.Position{x: x, y: y, facing: facing} = robot
        # is_obs = ToyRobot.PhoenixSocketClient.send_robot_status(channel, robot)
        stop(robot, goal_x, goal_y, channel)
      end
      %ToyRobot.Position{x: x, y: y, facing: facing} = robot

    else
      robot = move(robot);
      %ToyRobot.Position{x: x, y: y, facing: facing} = robot
      is_obs = ToyRobot.PhoenixSocketClient.send_robot_status(channel, robot)
      robot = right(robot);
      %ToyRobot.Position{x: x, y: y, facing: facing} = robot
      is_obs = ToyRobot.PhoenixSocketClient.send_robot_status(channel, robot)
      if (is_obs) do
        repeat = 0
        objInY_north(robot, goal_x, goal_y, channel, repeat)
      else
        robot = move(robot)
        # is_obs = ToyRobot.PhoenixSocketClient.send_robot_status(channel, robot)
        %ToyRobot.Position{x: x, y: y, facing: facing} = robot
        if (x != goal_x) do
          correct_X(robot, goal_x, goal_y, channel)
        else
          stop(robot, goal_x, goal_y, channel)
        end
      end
      %ToyRobot.Position{x: x, y: y, facing: facing} = robot
      # IO.puts("exited else")
    end

  end

  %ToyRobot.Position{x: x, y: y, facing: facing} = robot
  # IO.puts("#{x}, #{y}, #{facing}")
  #call the base stop func at this point

end


def objInY_south(%ToyRobot.Position{x: x, y: y, facing: facing} = robot, goal_x, goal_y, channel, repeat) do

  # make sure bot is facing south
  # IO.puts("in south")

  %ToyRobot.Position{x: x, y: y, facing: facing} = robot
  if (x == 1) or (repeat == 1) do  #turn, move left and face south
    robot = left(robot);
    %ToyRobot.Position{x: x, y: y, facing: facing} = robot
    is_obs = ToyRobot.PhoenixSocketClient.send_robot_status(channel, robot)

    if(is_obs) do
      robot = left(robot)
      %ToyRobot.Position{x: x, y: y, facing: facing} = robot
      is_obs = ToyRobot.PhoenixSocketClient.send_robot_status(channel, robot)
      robot = move(robot)
      %ToyRobot.Position{x: x, y: y, facing: facing} = robot
      is_obs = ToyRobot.PhoenixSocketClient.send_robot_status(channel, robot)
      robot = right(robot)
      %ToyRobot.Position{x: x, y: y, facing: facing} = robot
      is_obs = ToyRobot.PhoenixSocketClient.send_robot_status(channel, robot)

      if(is_obs) do
        objInX_east(%ToyRobot.Position{x: x, y: y, facing: facing} = robot, goal_x, goal_y, channel, repeat = 0)
      else
        robot = move(robot)
        %ToyRobot.Position{x: x, y: y, facing: facing} = robot
        # is_obs = ToyRobot.PhoenixSocketClient.send_robot_status(channel, robot)
        stop(robot, goal_x, goal_y, channel)

      end
      %ToyRobot.Position{x: x, y: y, facing: facing} = robot

    else
      robot = move(robot);
      %ToyRobot.Position{x: x, y: y, facing: facing} = robot
      is_obs = ToyRobot.PhoenixSocketClient.send_robot_status(channel, robot)
      robot = right(robot);
      %ToyRobot.Position{x: x, y: y, facing: facing} = robot
      is_obs = ToyRobot.PhoenixSocketClient.send_robot_status(channel, robot)
      if (is_obs) do
        repeat = 1
        objInY_south(robot, goal_x, goal_y, channel, repeat)
      else
        robot = move(robot)
        %ToyRobot.Position{x: x, y: y, facing: facing} = robot
        # is_obs = ToyRobot.PhoenixSocketClient.send_robot_status(channel, robot)
        if (x != goal_x) do
          correct_X(robot, goal_x, goal_y, channel)
        else
          stop(robot, goal_x, goal_y, channel)
        end
      end
      %ToyRobot.Position{x: x, y: y, facing: facing} = robot
      # IO.puts("exited else")
    end

  else #turn, move right and go south
    robot = right(robot);
    %ToyRobot.Position{x: x, y: y, facing: facing} = robot
    is_obs = ToyRobot.PhoenixSocketClient.send_robot_status(channel, robot)

    if(is_obs) do
      robot = right(robot)
      %ToyRobot.Position{x: x, y: y, facing: facing} = robot
      is_obs = ToyRobot.PhoenixSocketClient.send_robot_status(channel, robot)
      robot = move(robot)
      %ToyRobot.Position{x: x, y: y, facing: facing} = robot
      is_obs = ToyRobot.PhoenixSocketClient.send_robot_status(channel, robot)
      robot = left(robot)
      %ToyRobot.Position{x: x, y: y, facing: facing} = robot
      is_obs = ToyRobot.PhoenixSocketClient.send_robot_status(channel, robot)

      if(is_obs) do
        objInX_west(%ToyRobot.Position{x: x, y: y, facing: facing} = robot, goal_x, goal_y, channel, repeat = 0)
      else
        robot = move(robot)
        %ToyRobot.Position{x: x, y: y, facing: facing} = robot
        # is_obs = ToyRobot.PhoenixSocketClient.send_robot_status(channel, robot)
        stop(robot, goal_x, goal_y, channel)
      end
      %ToyRobot.Position{x: x, y: y, facing: facing} = robot

    else
      robot = move(robot);
      %ToyRobot.Position{x: x, y: y, facing: facing} = robot
      is_obs = ToyRobot.PhoenixSocketClient.send_robot_status(channel, robot)
      robot = left(robot);
      is_obs = ToyRobot.PhoenixSocketClient.send_robot_status(channel, robot)
      %ToyRobot.Position{x: x, y: y, facing: facing} = robot
      if (is_obs) do
        repeat = 0
        objInY_south(robot, goal_x, goal_y, channel, repeat)
      else
        robot = move(robot)
        %ToyRobot.Position{x: x, y: y, facing: facing} = robot
        # is_obs = ToyRobot.PhoenixSocketClient.send_robot_status(channel, robot)
        if (x != goal_x) do
          correct_X(robot, goal_x, goal_y, channel)
        else
          stop(robot, goal_x, goal_y, channel)
        end
      end
      %ToyRobot.Position{x: x, y: y, facing: facing} = robot
      # IO.puts("exited if")
    end


  end
  %ToyRobot.Position{x: x, y: y, facing: facing} = robot
  #call the base stop func at this point
  # stop(robot, goal_x, goal_y, channel)
end

def objInX_west(%ToyRobot.Position{x: x, y: y, facing: facing} = robot, goal_x, goal_y, channel, repeat) do

  # make sure bot is facing west before running this func
  # IO.puts("in west")

  %ToyRobot.Position{x: x, y: y, facing: facing} = robot

  if (y == :a) or (repeat == 1) do  #turn, move left and face east
    robot = right(robot);
    %ToyRobot.Position{x: x, y: y, facing: facing} = robot
    is_obs = ToyRobot.PhoenixSocketClient.send_robot_status(channel, robot)


    if(is_obs) do
      robot = right(robot)
      %ToyRobot.Position{x: x, y: y, facing: facing} = robot
      is_obs = ToyRobot.PhoenixSocketClient.send_robot_status(channel, robot)
      robot = move(robot)
      %ToyRobot.Position{x: x, y: y, facing: facing} = robot
      is_obs = ToyRobot.PhoenixSocketClient.send_robot_status(channel, robot)
      robot = left(robot)
      %ToyRobot.Position{x: x, y: y, facing: facing} = robot
      is_obs = ToyRobot.PhoenixSocketClient.send_robot_status(channel, robot)

      if(is_obs) do
        objInY_north(%ToyRobot.Position{x: x, y: y, facing: facing} = robot, goal_x, goal_y, channel, repeat = 0)
      else
        robot = move(robot)
        %ToyRobot.Position{x: x, y: y, facing: facing} = robot
        # is_obs = ToyRobot.PhoenixSocketClient.send_robot_status(channel, robot)
        correct_X(robot, goal_x, goal_y, channel)
      end
      %ToyRobot.Position{x: x, y: y, facing: facing} = robot

    else
      robot = move(robot);
      %ToyRobot.Position{x: x, y: y, facing: facing} = robot
      is_obs = ToyRobot.PhoenixSocketClient.send_robot_status(channel, robot)
      robot = left(robot);
      is_obs = ToyRobot.PhoenixSocketClient.send_robot_status(channel, robot)
      %ToyRobot.Position{x: x, y: y, facing: facing} = robot
      if (is_obs) do
        repeat = 1
        objInX_west(robot, goal_x, goal_y, channel, repeat)
      else
        robot = move(robot)
        # is_obs = ToyRobot.PhoenixSocketClient.send_robot_status(channel, robot)
        %ToyRobot.Position{x: x, y: y, facing: facing} = robot
        stop(robot, goal_x, goal_y, channel)
      end
      %ToyRobot.Position{x: x, y: y, facing: facing} = robot
      # IO.puts("exited if")
    end


  else #turn, move right and go south

    robot = left(robot);
    %ToyRobot.Position{x: x, y: y, facing: facing} = robot
    is_obs = ToyRobot.PhoenixSocketClient.send_robot_status(channel, robot)


    if(is_obs) do
      robot = left(robot)
      %ToyRobot.Position{x: x, y: y, facing: facing} = robot
      is_obs = ToyRobot.PhoenixSocketClient.send_robot_status(channel, robot)
      robot = move(robot)
      %ToyRobot.Position{x: x, y: y, facing: facing} = robot
      is_obs = ToyRobot.PhoenixSocketClient.send_robot_status(channel, robot)
      robot = right(robot)
      %ToyRobot.Position{x: x, y: y, facing: facing} = robot
      is_obs = ToyRobot.PhoenixSocketClient.send_robot_status(channel, robot)

      if(is_obs) do
        objInY_south(%ToyRobot.Position{x: x, y: y, facing: facing} = robot, goal_x, goal_y, channel, repeat = 0)
      else
        robot = move(robot)
        %ToyRobot.Position{x: x, y: y, facing: facing} = robot
        # is_obs = ToyRobot.PhoenixSocketClient.send_robot_status(channel, robot)
        correct_X(robot, goal_x, goal_y, channel)
      end
      %ToyRobot.Position{x: x, y: y, facing: facing} = robot

    else
      robot = move(robot);
      %ToyRobot.Position{x: x, y: y, facing: facing} = robot
      is_obs = ToyRobot.PhoenixSocketClient.send_robot_status(channel, robot)
      robot = right(robot);
      %ToyRobot.Position{x: x, y: y, facing: facing} = robot
      is_obs = ToyRobot.PhoenixSocketClient.send_robot_status(channel, robot)
      if (is_obs) do
        repeat = 0
        objInX_west(robot, goal_x, goal_y, channel, repeat)
      else
        robot = move(robot)
        %ToyRobot.Position{x: x, y: y, facing: facing} = robot
        # is_obs = ToyRobot.PhoenixSocketClient.send_robot_status(channel, robot)
        stop(robot, goal_x, goal_y, channel)
      end
      %ToyRobot.Position{x: x, y: y, facing: facing} = robot
      # IO.puts("exited else")
    end

  end
  %ToyRobot.Position{x: x, y: y, facing: facing} = robot
  #call the base stop func at this point
  # stop(robot, goal_x, goal_y, channel)
end

def objInX_east(%ToyRobot.Position{x: x, y: y, facing: facing} = robot, goal_x, goal_y, channel, repeat) do

  # make sure bot is facing east before running this func
  # IO.puts("in east")

  %ToyRobot.Position{x: x, y: y, facing: facing} = robot

  if (y == :a) or (repeat == 1) do  #turn, move left and face west
                #boundry case
    # IO.puts("in y=a")
    robot = left(robot)
    %ToyRobot.Position{x: x, y: y, facing: facing} = robot
    is_obs = ToyRobot.PhoenixSocketClient.send_robot_status(channel, robot)

    if(is_obs) do
      robot = left(robot)
      %ToyRobot.Position{x: x, y: y, facing: facing} = robot
      is_obs = is_obs = ToyRobot.PhoenixSocketClient.send_robot_status(channel, robot)
      robot = move(robot)
      %ToyRobot.Position{x: x, y: y, facing: facing} = robot
      is_obs = ToyRobot.PhoenixSocketClient.send_robot_status(channel, robot)
      robot = right(robot)
      %ToyRobot.Position{x: x, y: y, facing: facing} = robot
      is_obs = ToyRobot.PhoenixSocketClient.send_robot_status(channel, robot)

      if(is_obs) do
        objInY_north(%ToyRobot.Position{x: x, y: y, facing: facing} = robot, goal_x, goal_y, channel, repeat = 0)
      else
        robot = move(robot)
        %ToyRobot.Position{x: x, y: y, facing: facing} = robot
        # is_obs = ToyRobot.PhoenixSocketClient.send_robot_status(channel, robot)
        correct_X(robot, goal_x, goal_y, channel)
      end
      %ToyRobot.Position{x: x, y: y, facing: facing} = robot

    else
      robot = move(robot);
      %ToyRobot.Position{x: x, y: y, facing: facing} = robot
      is_obs = ToyRobot.PhoenixSocketClient.send_robot_status(channel, robot)
      robot = right(robot);
      %ToyRobot.Position{x: x, y: y, facing: facing} = robot
      is_obs = ToyRobot.PhoenixSocketClient.send_robot_status(channel, robot)
      if (is_obs) do
        repeat = 1
        objInX_east(robot, goal_x, goal_y, channel, repeat)
      else
        robot = move(robot)
        %ToyRobot.Position{x: x, y: y, facing: facing} = robot
        stop(robot, goal_x, goal_y, channel)
      end
      %ToyRobot.Position{x: x, y: y, facing: facing} = robot

      #is_obs = ToyRobot.PhoenixSocketClient.send_robot_status(channel, robot)
      # IO.puts("exited else")
    end

  else #turn, move right and face east//
    # IO.puts("in else")
    robot = right(robot);
    %ToyRobot.Position{x: x, y: y, facing: facing} = robot
    is_obs = ToyRobot.PhoenixSocketClient.send_robot_status(channel, robot)

    if(is_obs) do
      # IO.puts("in isobs")
      robot = right(robot)
      %ToyRobot.Position{x: x, y: y, facing: facing} = robot
      is_obs = ToyRobot.PhoenixSocketClient.send_robot_status(channel, robot)

      robot = move(robot)
      %ToyRobot.Position{x: x, y: y, facing: facing} = robot
      is_obs = ToyRobot.PhoenixSocketClient.send_robot_status(channel, robot)

      robot = left(robot)
      %ToyRobot.Position{x: x, y: y, facing: facing} = robot
      is_obs = ToyRobot.PhoenixSocketClient.send_robot_status(channel, robot)

      if(is_obs) do
        objInY_south(%ToyRobot.Position{x: x, y: y, facing: facing} = robot, goal_x, goal_y, channel, repeat = 0)
      else
        robot = move(robot)
        %ToyRobot.Position{x: x, y: y, facing: facing} = robot
        # is_obs = ToyRobot.PhoenixSocketClient.send_robot_status(channel, robot)
        correct_X(robot, goal_x, goal_y, channel)
      end
      %ToyRobot.Position{x: x, y: y, facing: facing} = robot

    else
      # IO.puts("in else isobs")
      robot = move(robot);
      %ToyRobot.Position{x: x, y: y, facing: facing} = robot
      is_obs = ToyRobot.PhoenixSocketClient.send_robot_status(channel, robot)
      robot = left(robot);
      is_obs = ToyRobot.PhoenixSocketClient.send_robot_status(channel, robot)
      %ToyRobot.Position{x: x, y: y, facing: facing} = robot

      if (is_obs) do
        # IO.puts("in unwanted")
        repeat = 0
        objInX_east(robot, goal_x, goal_y, channel, repeat)
      else
        # IO.puts("in wanted")
        robot = move(robot)
        %ToyRobot.Position{x: x, y: y, facing: facing} = robot
        # is_obs = ToyRobot.PhoenixSocketClient.send_robot_status(channel, robot)
        stop(robot, goal_x, goal_y, channel)
      end
      %ToyRobot.Position{x: x, y: y, facing: facing} = robot
      # IO.puts("exited if")
    end

  end

  %ToyRobot.Position{x: x, y: y, facing: facing} = robot
  #call the base stop func at this point
  # stop(robot, goal_x, goal_y, channel)
end

 @doc """
  Places the robot to the provided position of (x, y, facing),
  but prevents it to be placed outside of the table and facing invalid direction.

  Examples:

      iex> ToyRobot.place(1, :b, :south)
      {:ok, %ToyRobot.Position{facing: :south, x: 1, y: :b}}

      iex> ToyRobot.place(-1, :f, :north)
      {:failure, "Invalid position"}

      iex> ToyRobot.place(3, :c, :north_east)
      {:failure, "Invalid facing direction"}
  """

  def place(x, y, facing) do
    {:ok, %ToyRobot.Position{x: x, y: y, facing: facing}}
  end

  @doc """
  Provide START position to the robot as given location of (x, y, facing) and place it.
  """
  def start(x, y, facing) do
    ###########################
    ## complete this funcion ##
    ###########################
    {:ok, %ToyRobot.Position{x: x, y: y, facing: facing}}
    place(x, y, facing)
  end

  def stop(robot, goal_x, goal_y, _channel) when goal_x < 1 or goal_y < :a or goal_x > @table_top_x or goal_y > @table_top_y do
    {:failure, "Invalid STOP position"}
  end

  @doc """
  Provide STOP position to the robot as given location of (x, y) and plan the path from START to STOP.
  Passing the channel PID on the Phoenix Server that will be used to send robot's current status after each action is taken.
  Make a call to ToyRobot.PhoenixSocketClient.send_robot_status/2
  to get the indication of obstacle presence ahead of the robot.
  """
  def stop(%ToyRobot.Position{x: x, y: y, facing: facing} = robot, goal_x, goal_y, channel) do

    ###########################
    ## complete this funcion ##
    ###########################
    IO.inspect(robot)
    if (y == goal_y) and (x == goal_x) do
      %ToyRobot.Position{x: x, y: y, facing: facing} = robot
      is_obs = ToyRobot.PhoenixSocketClient.send_robot_status(channel, robot)
      {:ok,robot}

    else
      is_obs = ToyRobot.PhoenixSocketClient.send_robot_status(channel, robot)
      # IO.inspect(robot)
      # IO.puts("----")

      if y < goal_y do

        if (facing != :north) do
          robot = right(robot)
          %ToyRobot.Position{x: x, y: y, facing: facing} = robot
          #is_obs = ToyRobot.PhoenixSocketClient.send_robot_status(channel, robot)
          # send_robot_status(robot, channel)
          stop(robot, goal_x, goal_y, channel)

        else
          # is_obs = ToyRobot.PhoenixSocketClient.send_robot_status(channel, robot)
          %ToyRobot.Position{x: x, y: y, facing: facing} = robot
          # is_obs = ToyRobot.PhoenixSocketClient.send_robot_status(channel, robot)

          if(is_obs) do
          #  IO.put("Obstacle at #{x}, #{y + 1}")
          # IO.puts("Obstacle at #{x}, #{y}, #{facing}")

           objInY_north(robot, goal_x, goal_y, channel, repeat = 0)
           %ToyRobot.Position{x: x, y: y, facing: facing} = robot

          else
            # %ToyRobot.Position{x: x, y: y, facing: facing} = robot
            # is_obs = ToyRobot.PhoenixSocketClient.send_robot_status(channel, robot)
            robot = move(robot)
            %ToyRobot.Position{x: x, y: y, facing: facing} = robot
            # is_obs = ToyRobot.PhoenixSocketClient.send_robot_status(channel, robot)
            # send_robot_status(robot, channel)
            stop(robot, goal_x, goal_y, channel)
          end
        end


      else if y > goal_y do
        if (facing != :south) do
          robot = right(robot)
          %ToyRobot.Position{x: x, y: y, facing: facing} = robot
          #is_obs = ToyRobot.PhoenixSocketClient.send_robot_status(channel, robot)
          # send_robot_status(robot, channel)
          stop(robot, goal_x, goal_y, channel)

        else
          %ToyRobot.Position{x: x, y: y, facing: facing} = robot
          # is_obs = ToyRobot.PhoenixSocketClient.send_robot_status(channel, robot)

          if(is_obs) do
            # IO.put("Obstacle at #{x}, #{y - 1}")
            # IO.puts("Obstacle at #{x}, #{y}, #{facing}")

            objInY_south(robot, goal_x, goal_y, channel, repeat = 0)

            %ToyRobot.Position{x: x, y: y, facing: facing} = robot

          else
            %ToyRobot.Position{x: x, y: y, facing: facing} = robot
            robot = move(robot)
            %ToyRobot.Position{x: x, y: y, facing: facing} = robot
            stop(robot, goal_x, goal_y, channel)
          end
          # send_robot_status(robot, channel)
        end

      else
        if x > goal_x do
          if (facing != :west) do
            robot = right(robot)
            %ToyRobot.Position{x: x, y: y, facing: facing} = robot
            # send_robot_status(robot, channel)
            #is_obs = ToyRobot.PhoenixSocketClient.send_robot_status(channel, robot)
            stop(robot, goal_x, goal_y, channel)
          else
            %ToyRobot.Position{x: x, y: y, facing: facing} = robot
            # is_obs = ToyRobot.PhoenixSocketClient.send_robot_status(channel, robot)

            if(is_obs) do
              # IO.puts("Obstacle at #{x}, #{y}, #{facing}")
              objInX_west(robot, goal_x, goal_y, channel, repeat = 0)
              %ToyRobot.Position{x: x, y: y, facing: facing} = robot

            else
              robot = move(robot)
              %ToyRobot.Position{x: x, y: y, facing: facing} = robot
              stop(robot, goal_x, goal_y, channel)
            end
          end
            # send_robot_status(robot, channel)

        else if x < goal_x do
          # is_obs = ToyRobot.PhoenixSocketClient.send_robot_status(channel, robot)
          %ToyRobot.Position{x: x, y: y, facing: facing} = robot

          if (facing != :east) do
            robot = right(robot)
            %ToyRobot.Position{x: x, y: y, facing: facing} = robot
            # send_robot_status(robot, channel)
            #is_obs = ToyRobot.PhoenixSocketClient.send_robot_status(channel, robot)
            stop(robot, goal_x, goal_y, channel)

          else
            %ToyRobot.Position{x: x, y: y, facing: facing} = robot
            # is_obs = ToyRobot.PhoenixSocketClient.send_robot_status(channel, robot)

            if(is_obs) do
              # IO.put("Obstacle at #{x + 1}, #{y}")
              # IO.puts("Obstacle at #{x}, #{y}, #{facing}")
              objInX_east(robot, goal_x, goal_y, channel, repeat = 0)#-----
              %ToyRobot.Position{x: x, y: y, facing: facing} = robot


            else

              robot = move(robot)
              %ToyRobot.Position{x: x, y: y, facing: facing} = robot
              stop(robot, goal_x, goal_y, channel)
            end
          end

            # send_robot_status(robot, channel)

        else
          is_obs = ToyRobot.PhoenixSocketClient.send_robot_status(channel, robot)
          {:ok,robot}

        end
       end
      end
    end       # --> end for the main if - else
  end         # --> end for the main stop function

  end

  # def ToyRobot.PhoenixSocketClient.send_robot_status(robot,channel)do
  #   current = self()
  #   pid = spawn_link(fn -> x = send_robot_status(robot, channel)
  #                          send(current,x) end)
  #   Process.register(pid, :client_toyrobot)
  #   receive do
  #     value -> value
  #   end
  # end

  @doc """
  Provides the report of the robot's current position
  Examples:
      iex> {:ok, robot} = ToyRobot.place(2, :b, :west)
      iex> ToyRobot.report(robot)
      {2, :b, :west}
  """
  def report(%ToyRobot.Position{x: x, y: y, facing: facing} = robot) do
    {x, y, facing}
  end

  @directions_to_the_right %{north: :east, east: :south, south: :west, west: :north}
  @doc """
  Rotates the robot to the right
  """
  def right(%ToyRobot.Position{facing: facing} = robot) do
    %ToyRobot.Position{robot | facing: @directions_to_the_right[facing]}
  end

  @directions_to_the_left Enum.map(@directions_to_the_right, fn {from, to} -> {to, from} end)
  @doc """
  Rotates the robot to the left
  """
  def left(%ToyRobot.Position{facing: facing} = robot) do
    %ToyRobot.Position{robot | facing: @directions_to_the_left[facing]}
  end

  @doc """
  Moves the robot to the north, but prevents it to fall
  """
  def move(%ToyRobot.Position{x: _, y: y, facing: :north} = robot) when y < @table_top_y do
    %ToyRobot.Position{robot | y: Enum.find(@robot_map_y_atom_to_num, fn {_, val} -> val == Map.get(@robot_map_y_atom_to_num, y) + 1 end) |> elem(0)}
  end

  @doc """
  Moves the robot to the east, but prevents it to fall
  """
  def move(%ToyRobot.Position{x: x, y: _, facing: :east} = robot) when x < @table_top_x do
    %ToyRobot.Position{robot | x: x + 1}
  end

  @doc """
  Moves the robot to the south, but prevents it to fall
  """
  def move(%ToyRobot.Position{x: _, y: y, facing: :south} = robot) when y > :a do
    %ToyRobot.Position{robot | y: Enum.find(@robot_map_y_atom_to_num, fn {_, val} -> val == Map.get(@robot_map_y_atom_to_num, y) - 1 end) |> elem(0)}
  end

  @doc """
  Moves the robot to the west, but prevents it to fall
  """
  def move(%ToyRobot.Position{x: x, y: _, facing: :west} = robot) when x > 1 do
    %ToyRobot.Position{robot | x: x - 1}
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
