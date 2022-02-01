defmodule CLI.ToyRobotA do
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
  def start_link(robot) do
    GenServer.start_link(__MODULE__,robot,name: :robots_status)
  end

  def init(robot) do
    {:ok,{robot,false,false}}
  end

  def set_robot_a(robot_new,bool,bool_if_finished) do
    # Process.sleep(100)
    new_state = {robot_new,bool,bool_if_finished}
    GenServer.call(:robots_status,{:set,new_state})
  end
  def handle_call({:set,new_state}, _from, old_state) do
    {:reply, old_state, new_state}
  end

  def get_robot_a do
    # Process.sleep(1000)
    GenServer.call(:robots_status,{:get})
  end
  def handle_call({:get}, _from, state) do
    {:reply, state, state}
  end
  defmodule SortedListStruct do
    defstruct value: -1, index: -1
  end

  def sent_alt_status(robot, cli_proc_name) do
    # Process.sleep(1000)
    {robot_a, bool,bool_if_reached} = get_robot_a()
    # if(bool == false) do
      # IO.inspect({robot_a,bool})
    # IO.puts("hello there this is file a")
    # end
    bool =
      if bool_if_reached do
        false
      else
        bool
      end
    is_obs =
    if bool == false do
      # IO.puts("file A: ")
      # IO.puts("printing form here")
      is_obs = check_for_obs(robot, cli_proc_name)
      set_robot_a(robot,true,bool_if_reached)
      # Process.sleep(100)
      is_obs
    else
      is_obs = sent_alt_status(robot,cli_proc_name)
      is_obs
    end
    is_obs
  end
  def sent_alt_statuss(robot, cli_proc_name,bool_if_reached) do
    # IO.puts("hello there")
    set_robot_a(robot,true,true)
  end
  def correct_X(%CLI.Position{x: x, y: y, facing: facing} = robot, goal_x, goal_y, cli_proc_name) do
    %CLI.Position{x: x, y: y, facing: facing} = robot

    if(goal_x == x) do
      # is_obs = sent_alt_status(robot, cli_proc_name)
      go_to_goal(robot, goal_x, goal_y, cli_proc_name)
      {:ok, robot}

    else
    is_obs = sent_alt_status(robot, cli_proc_name)
    if x > goal_x do

      if (facing != :west) do
        robot = right(robot)
        %CLI.Position{x: x, y: y, facing: facing} = robot
        # send_robot_status(robot, cli_proc_name)
        #is_obs = check_for_obs(robot,cli_proc_name)
        correct_X(robot, goal_x, goal_y, cli_proc_name)
      else
        %CLI.Position{x: x, y: y, facing: facing} = robot
        # is_obs = check_for_obs(robot,cli_proc_name)

        if(is_obs) do
          # IO.puts("Obstacle at #{x}, #{y}, #{facing}")
          objInX_west(robot, goal_x, goal_y, cli_proc_name, repeat = 0)
          %CLI.Position{x: x, y: y, facing: facing} = robot

        else
          robot = move(robot)
          %CLI.Position{x: x, y: y, facing: facing} = robot
          correct_X(robot, goal_x, goal_y, cli_proc_name)
        end
      end
        # send_robot_status(robot, cli_proc_name)

    else if x < goal_x do
      # is_obs = sent_alt_status(robot, cli_proc_name)
      %CLI.Position{x: x, y: y, facing: facing} = robot

      if (facing != :east) do
        robot = right(robot)
        %CLI.Position{x: x, y: y, facing: facing} = robot
        # send_robot_status(robot, cli_proc_name)
        #is_obs = check_for_obs(robot,cli_proc_name)
        correct_X(robot, goal_x, goal_y, cli_proc_name)

      else
        %CLI.Position{x: x, y: y, facing: facing} = robot
        # is_obs = check_for_obs(robot,cli_proc_name)

        if(is_obs) do
          # IO.put("Obstacle at #{x + 1}, #{y}")
          # IO.puts("Obstacle at #{x}, #{y}, #{facing}")
          objInX_east(robot, goal_x, goal_y, cli_proc_name, repeat = 0)
          %CLI.Position{x: x, y: y, facing: facing} = robot


        else
          robot = move(robot)
          %CLI.Position{x: x, y: y, facing: facing} = robot
          correct_X(robot, goal_x, goal_y, cli_proc_name)
        end
      end
    end
  end
end
end



  def objInY_north(%CLI.Position{x: x, y: y, facing: facing} = robot, goal_x, goal_y, cli_proc_name, repeat) do
    %CLI.Position{x: x, y: y, facing: facing} = robot

    # make sure bot is facing north
    # IO.puts("in north")
    if (x == 1) or (repeat == 1)  do  #turn and right and face north
      # IO.puts("in 1")
      robot = right(robot);
      %CLI.Position{x: x, y: y, facing: facing} = robot
      is_obs = sent_alt_status(robot, cli_proc_name)

      if(is_obs) do
        robot = right(robot)
        %CLI.Position{x: x, y: y, facing: facing} = robot
        is_obs = sent_alt_status(robot, cli_proc_name)
        robot = move(robot)
        %CLI.Position{x: x, y: y, facing: facing} = robot
        is_obs = sent_alt_status(robot, cli_proc_name)
        robot = left(robot)
        %CLI.Position{x: x, y: y, facing: facing} = robot
        is_obs = sent_alt_status(robot, cli_proc_name)

        if(is_obs) do
          objInX_east(%CLI.Position{x: x, y: y, facing: facing} = robot, goal_x, goal_y, cli_proc_name, repeat = 0)
        else
          robot = move(robot)
          %CLI.Position{x: x, y: y, facing: facing} = robot
          # is_obs = sent_alt_status(robot, cli_proc_name)
          go_to_goal(robot, goal_x, goal_y, cli_proc_name)
        end
        %CLI.Position{x: x, y: y, facing: facing} = robot

      else
        robot = move(robot);
        %CLI.Position{x: x, y: y, facing: facing} = robot
        is_obs = sent_alt_status(robot, cli_proc_name)
        robot = left(robot);
        is_obs = sent_alt_status(robot, cli_proc_name)
        %CLI.Position{x: x, y: y, facing: facing} = robot
        if (is_obs) do
          repeat = 1
          objInY_north(robot, goal_x, goal_y, cli_proc_name, repeat)
        else
          robot = move(robot)
          %CLI.Position{x: x, y: y, facing: facing} = robot
          #is_obs = sent_alt_status(robot, cli_proc_name)
          if (x != goal_x) do
            correct_X(robot, goal_x, goal_y, cli_proc_name)
          else
            go_to_goal(robot, goal_x, goal_y, cli_proc_name)
          end
        end
        %CLI.Position{x: x, y: y, facing: facing} = robot

        # IO.puts("exited if")
      end

    else #turn and move left and face north
      # IO.puts("in 2")
      robot = left(robot);
      %CLI.Position{x: x, y: y, facing: facing} = robot
      is_obs = sent_alt_status(robot, cli_proc_name)

      if(is_obs) do
        robot = left(robot)
        %CLI.Position{x: x, y: y, facing: facing} = robot
        is_obs = sent_alt_status(robot, cli_proc_name)
        robot = move(robot)
        %CLI.Position{x: x, y: y, facing: facing} = robot
        is_obs = sent_alt_status(robot, cli_proc_name)
        robot = right(robot)
        %CLI.Position{x: x, y: y, facing: facing} = robot
        is_obs = sent_alt_status(robot, cli_proc_name)

        if(is_obs) do
          objInX_west(%CLI.Position{x: x, y: y, facing: facing} = robot, goal_x, goal_y, cli_proc_name, repeat = 0)
        else
          robot = move(robot)
          %CLI.Position{x: x, y: y, facing: facing} = robot
          # is_obs = sent_alt_status(robot, cli_proc_name)
          go_to_goal(robot, goal_x, goal_y, cli_proc_name)
        end
        %CLI.Position{x: x, y: y, facing: facing} = robot

      else
        robot = move(robot);
        %CLI.Position{x: x, y: y, facing: facing} = robot
        is_obs = sent_alt_status(robot, cli_proc_name)
        robot = right(robot);
        %CLI.Position{x: x, y: y, facing: facing} = robot
        is_obs = sent_alt_status(robot, cli_proc_name)
        if (is_obs) do
          repeat = 0
          objInY_north(robot, goal_x, goal_y, cli_proc_name, repeat)
        else
          robot = move(robot)
          # is_obs = sent_alt_status(robot, cli_proc_name)
          %CLI.Position{x: x, y: y, facing: facing} = robot
          if (x != goal_x) do
            correct_X(robot, goal_x, goal_y, cli_proc_name)
          else
            go_to_goal(robot, goal_x, goal_y, cli_proc_name)
          end
        end
        %CLI.Position{x: x, y: y, facing: facing} = robot
        # IO.puts("exited else")
      end

    end

    %CLI.Position{x: x, y: y, facing: facing} = robot
    # IO.puts("#{x}, #{y}, #{facing}")
    #call the base go_to_goal func at this point

  end


  def objInY_south(%CLI.Position{x: x, y: y, facing: facing} = robot, goal_x, goal_y, cli_proc_name, repeat) do

    # make sure bot is facing south
    # IO.puts("in south")

    %CLI.Position{x: x, y: y, facing: facing} = robot
    if (x == 1) or (repeat == 1) do  #turn, move left and face south
      robot = left(robot);
      %CLI.Position{x: x, y: y, facing: facing} = robot
      is_obs = sent_alt_status(robot, cli_proc_name)

      if(is_obs) do
        robot = left(robot)
        %CLI.Position{x: x, y: y, facing: facing} = robot
        is_obs = sent_alt_status(robot, cli_proc_name)
        robot = move(robot)
        %CLI.Position{x: x, y: y, facing: facing} = robot
        is_obs = sent_alt_status(robot, cli_proc_name)
        robot = right(robot)
        %CLI.Position{x: x, y: y, facing: facing} = robot
        is_obs = sent_alt_status(robot, cli_proc_name)

        if(is_obs) do
          objInX_east(%CLI.Position{x: x, y: y, facing: facing} = robot, goal_x, goal_y, cli_proc_name, repeat = 0)
        else
          robot = move(robot)
          %CLI.Position{x: x, y: y, facing: facing} = robot
          # is_obs = sent_alt_status(robot, cli_proc_name)
          go_to_goal(robot, goal_x, goal_y, cli_proc_name)

        end
        %CLI.Position{x: x, y: y, facing: facing} = robot

      else
        robot = move(robot);
        %CLI.Position{x: x, y: y, facing: facing} = robot
        is_obs = sent_alt_status(robot, cli_proc_name)
        robot = right(robot);
        %CLI.Position{x: x, y: y, facing: facing} = robot
        is_obs = sent_alt_status(robot, cli_proc_name)
        if (is_obs) do
          repeat = 1
          objInY_south(robot, goal_x, goal_y, cli_proc_name, repeat)
        else
          robot = move(robot)
          %CLI.Position{x: x, y: y, facing: facing} = robot
          # is_obs = sent_alt_status(robot, cli_proc_name)
          if (x != goal_x) do
            correct_X(robot, goal_x, goal_y, cli_proc_name)
          else
            go_to_goal(robot, goal_x, goal_y, cli_proc_name)
          end
        end
        %CLI.Position{x: x, y: y, facing: facing} = robot
        # IO.puts("exited else")
      end

    else #turn, move right and go south
      robot = right(robot);
      %CLI.Position{x: x, y: y, facing: facing} = robot
      is_obs = sent_alt_status(robot, cli_proc_name)

      if(is_obs) do
        robot = right(robot)
        %CLI.Position{x: x, y: y, facing: facing} = robot
        is_obs = sent_alt_status(robot, cli_proc_name)
        robot = move(robot)
        %CLI.Position{x: x, y: y, facing: facing} = robot
        is_obs = sent_alt_status(robot, cli_proc_name)
        robot = left(robot)
        %CLI.Position{x: x, y: y, facing: facing} = robot
        is_obs = sent_alt_status(robot, cli_proc_name)

        if(is_obs) do
          objInX_west(%CLI.Position{x: x, y: y, facing: facing} = robot, goal_x, goal_y, cli_proc_name, repeat = 0)
        else
          robot = move(robot)
          %CLI.Position{x: x, y: y, facing: facing} = robot
          # is_obs = sent_alt_status(robot, cli_proc_name)
          go_to_goal(robot, goal_x, goal_y, cli_proc_name)
        end
        %CLI.Position{x: x, y: y, facing: facing} = robot

      else
        robot = move(robot);
        %CLI.Position{x: x, y: y, facing: facing} = robot
        is_obs = sent_alt_status(robot, cli_proc_name)
        robot = left(robot);
        is_obs = sent_alt_status(robot, cli_proc_name)
        %CLI.Position{x: x, y: y, facing: facing} = robot
        if (is_obs) do
          repeat = 0
          objInY_south(robot, goal_x, goal_y, cli_proc_name, repeat)
        else
          robot = move(robot)
          %CLI.Position{x: x, y: y, facing: facing} = robot
          # is_obs = sent_alt_status(robot, cli_proc_name)
          if (x != goal_x) do
            correct_X(robot, goal_x, goal_y, cli_proc_name)
          else
            go_to_goal(robot, goal_x, goal_y, cli_proc_name)
          end
        end
        %CLI.Position{x: x, y: y, facing: facing} = robot
        # IO.puts("exited if")
      end


    end
    %CLI.Position{x: x, y: y, facing: facing} = robot
    #call the base go_to_goal func at this point
    # go_to_goal(robot, goal_x, goal_y, cli_proc_name)
  end

  def objInX_west(%CLI.Position{x: x, y: y, facing: facing} = robot, goal_x, goal_y, cli_proc_name, repeat) do

    # make sure bot is facing west before running this func
    # IO.puts("in west")

    %CLI.Position{x: x, y: y, facing: facing} = robot

    if (y == :a) or (repeat == 1) do  #turn, move left and face east
      robot = right(robot);
      %CLI.Position{x: x, y: y, facing: facing} = robot
      is_obs = sent_alt_status(robot, cli_proc_name)


      if(is_obs) do
        robot = right(robot)
        %CLI.Position{x: x, y: y, facing: facing} = robot
        is_obs = sent_alt_status(robot, cli_proc_name)
        robot = move(robot)
        %CLI.Position{x: x, y: y, facing: facing} = robot
        is_obs = sent_alt_status(robot, cli_proc_name)
        robot = left(robot)
        %CLI.Position{x: x, y: y, facing: facing} = robot
        is_obs = sent_alt_status(robot, cli_proc_name)

        if(is_obs) do
          objInY_north(%CLI.Position{x: x, y: y, facing: facing} = robot, goal_x, goal_y, cli_proc_name, repeat = 0)
        else
          robot = move(robot)
          %CLI.Position{x: x, y: y, facing: facing} = robot
          # is_obs = sent_alt_status(robot, cli_proc_name)
          correct_X(robot, goal_x, goal_y, cli_proc_name)
        end
        %CLI.Position{x: x, y: y, facing: facing} = robot

      else
        robot = move(robot);
        %CLI.Position{x: x, y: y, facing: facing} = robot
        is_obs = sent_alt_status(robot, cli_proc_name)
        robot = left(robot);
        is_obs = sent_alt_status(robot, cli_proc_name)
        %CLI.Position{x: x, y: y, facing: facing} = robot
        if (is_obs) do
          repeat = 1
          objInX_west(robot, goal_x, goal_y, cli_proc_name, repeat)
        else
          robot = move(robot)
          # is_obs = sent_alt_status(robot, cli_proc_name)
          %CLI.Position{x: x, y: y, facing: facing} = robot
          go_to_goal(robot, goal_x, goal_y, cli_proc_name)
        end
        %CLI.Position{x: x, y: y, facing: facing} = robot
        # IO.puts("exited if")
      end


    else #turn, move right and go south

      robot = left(robot);
      %CLI.Position{x: x, y: y, facing: facing} = robot
      is_obs = sent_alt_status(robot, cli_proc_name)


      if(is_obs) do
        robot = left(robot)
        %CLI.Position{x: x, y: y, facing: facing} = robot
        is_obs = sent_alt_status(robot, cli_proc_name)
        robot = move(robot)
        %CLI.Position{x: x, y: y, facing: facing} = robot
        is_obs = sent_alt_status(robot, cli_proc_name)
        robot = right(robot)
        %CLI.Position{x: x, y: y, facing: facing} = robot
        is_obs = sent_alt_status(robot, cli_proc_name)

        if(is_obs) do
          objInY_south(%CLI.Position{x: x, y: y, facing: facing} = robot, goal_x, goal_y, cli_proc_name, repeat = 0)
        else
          robot = move(robot)
          %CLI.Position{x: x, y: y, facing: facing} = robot
          # is_obs = sent_alt_status(robot, cli_proc_name)
          correct_X(robot, goal_x, goal_y, cli_proc_name)
        end
        %CLI.Position{x: x, y: y, facing: facing} = robot

      else
        robot = move(robot);
        %CLI.Position{x: x, y: y, facing: facing} = robot
        is_obs = sent_alt_status(robot, cli_proc_name)
        robot = right(robot);
        %CLI.Position{x: x, y: y, facing: facing} = robot
        is_obs = sent_alt_status(robot, cli_proc_name)
        if (is_obs) do
          repeat = 0
          objInX_west(robot, goal_x, goal_y, cli_proc_name, repeat)
        else
          robot = move(robot)
          %CLI.Position{x: x, y: y, facing: facing} = robot
          # is_obs = sent_alt_status(robot, cli_proc_name)
          go_to_goal(robot, goal_x, goal_y, cli_proc_name)
        end
        %CLI.Position{x: x, y: y, facing: facing} = robot
        # IO.puts("exited else")
      end

    end
    %CLI.Position{x: x, y: y, facing: facing} = robot
    #call the base go_to_goal func at this point
    # go_to_goal(robot, goal_x, goal_y, cli_proc_name)
  end

  def objInX_east(%CLI.Position{x: x, y: y, facing: facing} = robot, goal_x, goal_y, cli_proc_name, repeat) do

    # make sure bot is facing east before running this func
    # IO.puts("in east")

    %CLI.Position{x: x, y: y, facing: facing} = robot

    if (y == :a) or (repeat == 1) do  #turn, move left and face west
                  #boundry case
      # IO.puts("in y=a")
      robot = left(robot)
      %CLI.Position{x: x, y: y, facing: facing} = robot
      is_obs = sent_alt_status(robot, cli_proc_name)

      if(is_obs) do
        robot = left(robot)
        %CLI.Position{x: x, y: y, facing: facing} = robot
        is_obs = sent_alt_status(robot, cli_proc_name)
        robot = move(robot)
        %CLI.Position{x: x, y: y, facing: facing} = robot
        is_obs = sent_alt_status(robot, cli_proc_name)
        robot = right(robot)
        %CLI.Position{x: x, y: y, facing: facing} = robot
        is_obs = sent_alt_status(robot, cli_proc_name)

        if(is_obs) do
          objInY_north(%CLI.Position{x: x, y: y, facing: facing} = robot, goal_x, goal_y, cli_proc_name, repeat = 0)
        else
          robot = move(robot)
          %CLI.Position{x: x, y: y, facing: facing} = robot
          # is_obs = sent_alt_status(robot, cli_proc_name)
          correct_X(robot, goal_x, goal_y, cli_proc_name)
        end
        %CLI.Position{x: x, y: y, facing: facing} = robot

      else
        robot = move(robot);
        %CLI.Position{x: x, y: y, facing: facing} = robot
        is_obs = sent_alt_status(robot, cli_proc_name)
        robot = right(robot);
        %CLI.Position{x: x, y: y, facing: facing} = robot
        is_obs = sent_alt_status(robot, cli_proc_name)
        if (is_obs) do
          repeat = 1
          objInX_east(robot, goal_x, goal_y, cli_proc_name, repeat)
        else
          robot = move(robot)
          %CLI.Position{x: x, y: y, facing: facing} = robot
          go_to_goal(robot, goal_x, goal_y, cli_proc_name)
        end
        %CLI.Position{x: x, y: y, facing: facing} = robot

        #is_obs = sent_alt_status(robot, cli_proc_name)
        # IO.puts("exited else")
      end

    else #turn, move right and face east//
      # IO.puts("in else")
      robot = right(robot);
      %CLI.Position{x: x, y: y, facing: facing} = robot
      is_obs = sent_alt_status(robot, cli_proc_name)

      if(is_obs) do
        # IO.puts("in isobs")
        robot = right(robot)
        %CLI.Position{x: x, y: y, facing: facing} = robot
        is_obs = sent_alt_status(robot, cli_proc_name)

        robot = move(robot)
        %CLI.Position{x: x, y: y, facing: facing} = robot
        is_obs = sent_alt_status(robot, cli_proc_name)

        robot = left(robot)
        %CLI.Position{x: x, y: y, facing: facing} = robot
        is_obs = sent_alt_status(robot, cli_proc_name)

        if(is_obs) do
          objInY_south(%CLI.Position{x: x, y: y, facing: facing} = robot, goal_x, goal_y, cli_proc_name, repeat = 0)
        else
          robot = move(robot)
          %CLI.Position{x: x, y: y, facing: facing} = robot
          # is_obs = sent_alt_status(robot, cli_proc_name)
          correct_X(robot, goal_x, goal_y, cli_proc_name)
        end
        %CLI.Position{x: x, y: y, facing: facing} = robot

      else
        # IO.puts("in else isobs")
        robot = move(robot);
        %CLI.Position{x: x, y: y, facing: facing} = robot
        is_obs = sent_alt_status(robot, cli_proc_name)
        robot = left(robot);
        is_obs = sent_alt_status(robot, cli_proc_name)
        %CLI.Position{x: x, y: y, facing: facing} = robot

        if (is_obs) do
          # IO.puts("in unwanted")
          repeat = 0
          objInX_east(robot, goal_x, goal_y, cli_proc_name, repeat)
        else
          # IO.puts("in wanted")
          robot = move(robot)
          %CLI.Position{x: x, y: y, facing: facing} = robot
          # is_obs = sent_alt_status(robot, cli_proc_name)
          go_to_goal(robot, goal_x, goal_y, cli_proc_name)
        end
        %CLI.Position{x: x, y: y, facing: facing} = robot
        # IO.puts("exited if")
      end

    end

    %CLI.Position{x: x, y: y, facing: facing} = robot
    #call the base go_to_goal func at this point
    # go_to_goal(robot, goal_x, goal_y, cli_proc_name)
  end

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
    {:failure, "Invalid go_to_goal position"}
  end

  @doc """
  Provide GOAL positions to the robot as given location of [(x1, y1),(x2, y2),..] and plan the path from START to these locations.
  Passing the CLI Server process name that will be used to send robot's current status after each action is taken.
  Spawn a process and register it with name ':client_toyrobotA' which is used by CLI Server to send an
  indication for the presence of obstacle ahead of robot's current position and facing.
  """
  def go_to_goal(%CLI.Position{x: x, y: y, facing: facing} = robot, goal_x, goal_y, cli_proc_name) do

    if (y == goal_y) and (x == goal_x) do

      is_obs = sent_alt_status(robot, cli_proc_name)
      robot
      # {:ok,robot}
    else
      # IO.inspect(robot)
      is_obs = sent_alt_status(robot, cli_proc_name)
      # IO.inspect(robot)
      # IO.puts("----")

      if y < goal_y do

        if (facing != :north) do
          robot = right(robot)

          #is_obs = check_for_obs(robot,cli_proc_name)
          # send_robot_status(robot, cli_proc_name)
          go_to_goal(robot, goal_x, goal_y, cli_proc_name)

        else
          # is_obs = sent_alt_status(robot, cli_proc_name)

          # is_obs = sent_alt_status(robot, cli_proc_name)

          if(is_obs) do
          #  IO.put("Obstacle at #{x}, #{y + 1}")
          # IO.puts("Obstacle at #{x}, #{y}, #{facing}")

           objInY_north(robot, goal_x, goal_y, cli_proc_name, repeat = 0)


          else
            # %CLI.Position{x: x, y: y, facing: facing} = robot
            # is_obs = sent_alt_status(robot, cli_proc_name)
            robot = move(robot)

            # is_obs = sent_alt_status(robot, cli_proc_name)
            # send_robot_status(robot, cli_proc_name)
            go_to_goal(robot, goal_x, goal_y, cli_proc_name)
          end
        end


      else if y > goal_y do
        if (facing != :south) do
          robot = right(robot)
          #is_obs = check_for_obs(robot,cli_proc_name)
          # send_robot_status(robot, cli_proc_name)
          go_to_goal(robot, goal_x, goal_y, cli_proc_name)

        else

          # is_obs = check_for_obs(robot,cli_proc_name)

          if(is_obs) do
            # IO.put("Obstacle at #{x}, #{y - 1}")
            # IO.puts("Obstacle at #{x}, #{y}, #{facing}")

            objInY_south(robot, goal_x, goal_y, cli_proc_name, repeat = 0)



          else

            robot = move(robot)

            go_to_goal(robot, goal_x, goal_y, cli_proc_name)
          end
          # send_robot_status(robot, cli_proc_name)
        end

      else
        if x > goal_x do
          if (facing != :west) do
            robot = right(robot)

            # send_robot_status(robot, cli_proc_name)
            #is_obs = check_for_obs(robot,cli_proc_name)
            go_to_goal(robot, goal_x, goal_y, cli_proc_name)
          else

            # is_obs = check_for_obs(robot,cli_proc_name)

            if(is_obs) do
              # IO.puts("Obstacle at #{x}, #{y}, #{facing}")
              objInX_west(robot, goal_x, goal_y, cli_proc_name, repeat = 0)


            else
              robot = move(robot)

              go_to_goal(robot, goal_x, goal_y, cli_proc_name)
            end
          end
            # send_robot_status(robot, cli_proc_name)

        else if x < goal_x do
          # is_obs = sent_alt_status(robot, cli_proc_name)

          if (facing != :east) do
            robot = right(robot)

            # send_robot_status(robot, cli_proc_name)
            #is_obs = check_for_obs(robot,cli_proc_name)
            go_to_goal(robot, goal_x, goal_y, cli_proc_name)

          else

            # is_obs = check_for_obs(robot,cli_proc_name)

            if(is_obs) do
              # IO.put("Obstacle at #{x + 1}, #{y}")
              # IO.puts("Obstacle at #{x}, #{y}, #{facing}")
              objInX_east(robot, goal_x, goal_y, cli_proc_name, repeat = 0)#-----



            else

              robot = move(robot)

              go_to_goal(robot, goal_x, goal_y, cli_proc_name)
            end
          end

            # send_robot_status(robot, cli_proc_name)

        else
          is_obs = sent_alt_status(robot, cli_proc_name)
          # {:ok,robot}

        end
       end
      end
    end       # --> end for the main if - else
  end         # --> end for the main go_to_goal function
  end
  ##############################################################################################
  def get_posB() do
    Process.sleep(200)
    # IO.puts("got robotB from :your_map_name in robot a file")
    Agent.get(:your_map_name, fn map -> Map.get(map, :robotB) end)
  end
  ###################################################################################################
  def dist_from_A(%CLI.Position{x: x, y: y, facing: facing} = robot, goal_locs, i) do
    y_map_atom_to_int = %{:a => 1, :b => 2, :c => 3, :d => 4, :e => 5}
    y_int = y_map_atom_to_int[y]
    y_dest_int = y_map_atom_to_int[String.to_atom(Enum.at(Enum.at(goal_locs, i), 1))]
    {k, ""} = Integer.parse(Enum.at(Enum.at(goal_locs, i), 0))
    abs(k - x) + abs(y_dest_int - y_int)
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

  def dist(%CLI.Position{x: x, y: y, facing: facing} = robot, goal_locs, i, index_list, dist_list) do
    # i = 0
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

  defp sort_B() do
    string = get_posB()
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
  ########################################################################################################3
  def give_A(a_data, i) do
    if (i == 0) do
      {:ok, pid} = Agent.start_link(fn -> %{} end)      #######################################################3
      Process.register(pid, :give_info_A)
    end
    # IO.puts("updated the a_data in :give_info_A in robot a file")
    Agent.update(:give_info_A, fn list -> a_data end)
    # Agent.update(agent, fn list -> ["eggs" | list] end)           #########################333333333333333
  end
  3###########################################################################################################
  def set_goal(a_data, b_data, i, goal_locs) do
    if(i < Map.count(a_data)) do
      k = Enum.at(a_data, i)
      j = Enum.at(b_data, i)

      if(k.value <= j.value and k.index <= j.index) do
        goal_A = Enum.at(goal_locs, k.index)
        # go_to_goal(goal_A)
      end
    end
  end
######################################################################################################################
  def wait_fot_conn() do
    # IO.puts("in conn a")
    Process.sleep(100)

    if (Enum.at(Agent.get(:movementB, fn list -> list end), 0) == 0) do###############################################
      # IO.inspect(Agent.get(:movementB, fn list -> list end))
      wait_fot_conn()
    end
  end
#####################################################################################################################
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
###########################################################################################################################
def visited_index(j, visited_index) do
  if(j == 0) do
    {:ok, pid} = Agent.start_link(fn -> %{} end)
    Process.register(pid, :indexes)                                           #################################################3
  end
  # IO.inspect("updated index list from robot a file")
  Agent.update(:indexes, fn list -> visited_index end)
end
###################################################################################################################################
  def get_goal(robot, goal_locs, i, reached_list, cli_proc_name, j, visited_index) do

    if(j != Enum.count(goal_locs)) do
    # IO.inspect(i)
    index_list = []
    dist_list = []
    # %CLI.Position{x: x, y: y, facing: facing} = robot
    #distancd of a from goal
    a_data = dist(robot, goal_locs, 0, index_list, dist_list)

    # IO.inspect(a_data)
    # IO.puts("with i")
    # IO.inspect(Enum.at(a_data, i))
    visited_index(j, visited_index)
    give_A(a_data, j)
    j = j + 1
    b_data = sort_B()
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
      get_goal(robot, goal_locs, i, reached_list, cli_proc_name, j, visited_index)
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
        get_goal(robot, goal_locs, i, reached_list, cli_proc_name, j, visited_index)
      else
        # goal_locs = List.delete_at(goal_locs, goal_index_A)
        i = 0
        visited_index = visited_index ++ [goal_index_A]
        visited_index(j, visited_index)
        # IO.puts("visited_index")
        # IO.inspect(visited_index)
        goal_x = String.to_integer(Enum.at(goal, 0))
        goal_y = String.to_atom(Enum.at(goal, 1))
        IO.inspect({"from robot-a",goal_x, goal_y})
        robot = go_to_goal(robot, goal_x, goal_y, cli_proc_name)
        # IO.puts("robot A")
        # IO.inspect(robot)
        get_goal(robot, goal_locs, i, reached_list, cli_proc_name, j, visited_index)
      end
      # get_goal(robot, goal_locs, i, reached_list, cli_proc_name)
    end
  else
    # IO.puts("reached here")
    sent_alt_statuss(robot,cli_proc_name,true)
  end
end
def repeat(robot, cli_proc_name) do
  is_obs = sent_alt_status(robot,cli_proc_name)
  repeat(robot,cli_proc_name)
end
  def stop(robot, goal_locs, cli_proc_name) do
    # IO.puts("in robot A")
    # IO.inspect(goal_locs)
    start_link(robot)
    get_goal(robot, goal_locs, 0, [], cli_proc_name, 0, [])
    # goal_x = String.to_integer(Enum.at(Enum.at(goal_locs, 0), 0))
    # goal_y = String.to_atom(Enum.at(Enum.at(goal_locs, 0), 1))
    # go_to_goal(%CLI.Position{x: x, y: y, facing: facing} = robot, goal_x, goal_y, cli_proc_name)
  end

  def check_for_obs(robot, cli_proc_name) do
    current = self()
    pid =
      spawn_link(fn ->
        x = send_robot_status(robot, cli_proc_name)
        send(current, x)
      end)
    Process.register(pid, :client_toyrobotA)
    # Process.sleep(1000)
    receive do
      value -> value
    end
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
