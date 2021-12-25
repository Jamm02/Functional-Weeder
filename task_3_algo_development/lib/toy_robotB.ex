defmodule CLI.ToyRobotB do
  # max x-coordinate of table top
  @table_top_x 5
  # max y-coordinate of table top
  @table_top_y :e
  # mapping of y-coordinates
  @robot_map_y_atom_to_num %{:a => 1, :b => 2, :c => 3, :d => 4, :e => 5}

  @doc """
  Places the robot to the default position of (1, A, North)

  Examples:

      iex> CLI.ToyRobotB.place
      {:ok, %CLI.Position{facing: :north, x: 1, y: :a}}
  """
  def sent_alt_statuss(robot, cli_proc_name,bool_if_reached) do
    # IO.puts("hello there")
    new_state = {robot,false,true}
    GenServer.call(:robots_status,{:set,new_state})
  end
  def sent_alt_status(robot, cli_proc_name) do
    # Process.sleep(1000)
    {robot_a,bool,bool_if_finished} = GenServer.call(:robots_status,{:get})
    # IO.inspect(bool_if_finished)
    # IO.puts("hello there this is file b")
    # IO.inspect({robot_a,bool})
    bool =
      if bool_if_finished do
        true
      else
        bool
      end
    # IO.inspect(bool)
    is_obs =
    if bool do
      # IO.puts("file B")
      # IO.puts("printing form here")
      is_obs = check_for_obs(robot, cli_proc_name)
      new_state = {robot_a,false,bool_if_finished}
      GenServer.call(:robots_status,{:set,new_state})
      # Process.sleep(100)
      is_obs
    else
      is_obs = sent_alt_status(robot,cli_proc_name)
      is_obs
    end
    is_obs
  end
  defmodule SortedListStruct do
    defstruct value: -1, index: -1
  end
  def dist_from_B(%CLI.Position{x: x, y: y, facing: facing} = robot, goal_locs, i) do
    y_map_atom_to_int = %{:a => 1, :b => 2, :c => 3, :d => 4, :e => 5}
    y_int = y_map_atom_to_int[y]

    y_dest_int = y_map_atom_to_int[String.to_atom(Enum.at(Enum.at(goal_locs, i), 1))]
    {k, ""} = Integer.parse(Enum.at(Enum.at(goal_locs, i), 0))
    abs(k - x) + abs(y_dest_int - y_int)
  end

  def add_index(dist_list, goal_locs, i, new_list) do
    if i < Enum.count(goal_locs) do
      # %OpenListStruct{x: x_p, y: y_p, facing: facing, f: _f} = current_node
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
    distance = dist_from_B(%CLI.Position{x: x, y: y, facing: facing} = robot, goal_locs, i)
    dist_list = dist_list ++ [distance]
    i = i + 1

    if i < Enum.count(goal_locs) do
      dist(robot, goal_locs, i, index_list, dist_list)
    else
      new_list = []
      new_list = add_index(dist_list, goal_locs, 0, new_list)
      # IO.inspect(new_list)
      new_list = Enum.sort(new_list, fn x, y -> x.value < y.value end)
      # IO.inspect(new_list)
    end
  end

  def put_info(new_list, finaldata, i) do
    if i < Enum.count(new_list) do
      temp_struct = Enum.at(new_list, i)
      value = to_string(temp_struct.value)
      finaldata = Enum.join([finaldata, value], ",")
      index = to_string(temp_struct.index)
      finaldata = Enum.join([finaldata, index], ",")
      i = i + 1
      put_info(new_list, finaldata, i)
    else
      finaldata
    end
  end

  def give_A_info(%CLI.Position{x: x, y: y, facing: facing} = robot, goal_locs, i) do
    if(i == 0) do
      {:ok, pid} = Agent.start_link(fn -> %{} end)
      Process.register(pid, :your_map_name)
    end
    data = to_string(x)
    finaldata = Enum.join([data, to_string(y)], ",")
    index_list = []
    dist_list = []

    new_list =
      dist(%CLI.Position{x: x, y: y, facing: facing} = robot, goal_locs, 0, index_list, dist_list)

    finaldata = put_info(new_list, finaldata, 0)
    Agent.update(:your_map_name, fn map -> Map.put(map, :robotB, finaldata) end)
  end

  def get_A() do
    Process.sleep(100)
    Agent.get(:give_info_A, fn list -> list end)
  end


  def wait_fot_conn() do
    # IO.puts("in conn b")

    Process.sleep(100)

    if (Enum.at(Agent.get(:movementA, fn list -> list end), 0) == 0) do
      # IO.inspect(Enum.at(Agent.get(:movementA, fn list -> list end), 0))
      wait_fot_conn()
    end
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

  @spec place(any, any, any) ::
          {:failure, <<_::128, _::_*64>>} | {:ok, %CLI.Position{facing: any, x: any, y: any}}
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

      iex> CLI.ToyRobotB.place(1, :b, :south)
      {:ok, %CLI.Position{facing: :south, x: 1, y: :b}}

      iex> CLI.ToyRobotB.place(-1, :f, :north)
      {:failure, "Invalid position"}

      iex> CLI.ToyRobotB.place(3, :c, :north_east)
      {:failure, "Invalid facing direction"}
  """
  def place(x, y, facing) do
    # IO.puts String.upcase("B I'm placed at => #{x},#{y},#{facing}")
    {:ok, %CLI.Position{x: x, y: y, facing: facing}}
  end

  @doc """
  Provide START position to the robot as given location of (x, y, facing) and place it.
  """
  def start(x, y, facing) do
    place(x, y, facing)
  end

  def place do
    place()
  end

  def stop(_robot, goal_x, goal_y, _cli_proc_name) when goal_x < 1 or goal_y < :a or goal_x > @table_top_x or goal_y > @table_top_y do
    {:failure, "Invalid STOP position"}
  end


  def go_to_goal(%CLI.Position{x: x, y: y, facing: facing} = robot, goal_x, goal_y, cli_proc_name) do

    if (y == goal_y) and (x == goal_x) do
      is_obs = sent_alt_status(robot, cli_proc_name)
      # IO.puts("go to goal b")
      # IO.inspect(robot)
      robot
      # {:ok,robot}

    else
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

def get_index_list() do
  Process.sleep(150)
  Agent.get(:indexes, fn list -> list end)
end

  def get_goal(robot, goal_locs, i, reached_list, cli_proc_name, j) do
    if(j != Enum.count(goal_locs)) do
      # IO.puts("B")
      # IO.inspect(get_index_list())
      # %CLI.Position{x: x, y: y, facing: facing} = robot
      # IO.inspect(robot)
      give_A_info(robot, goal_locs, j)
      j = j + 1
      a_data = get_A()

      index_list = []
      dist_list = []
      b_data =
      dist(%CLI.Position{x: x, y: y, facing: facing} = robot, goal_locs, 0, index_list, dist_list)

      # IO.puts("bdata")
      # IO.inspect(b_data)
      goal_index_A = Enum.at(a_data, i).index  #put 0, 1, 3 ... for next closest
      goal_value_A = Enum.at(a_data, i).value
      goal_value_B = Enum.at(b_data, i).value
      goal_index_B = Enum.at(b_data, i).index
      i = i + 1

      if ((((goal_index_A == goal_index_B) and (goal_value_A <= goal_value_B))) or (goal_value_B == 0) or (Enum.member?(get_index_list, goal_index_B))) do
        get_goal(robot, goal_locs, i, reached_list, cli_proc_name, j)
      else
        goal = Enum.at(goal_locs, goal_index_B)
        check_reached = check_reached_list(reached_list, Enum.count(reached_list) - 1, goal, [0])
        reached_list = reached_list ++ [goal]
        if (check_reached == [1]) do
          # i = i + 1
          get_goal(robot, goal_locs, i, reached_list, cli_proc_name, j)
        else
          # i = i + 1
          # IO.puts("goalB")
          # IO.inspect(goal)
          i = 0
          goal_x = String.to_integer(Enum.at(goal, 0))
          goal_y = String.to_atom(Enum.at(goal, 1))
          # IO.puts("robot b up")
          # IO.inspect(robot)
          robot = go_to_goal(robot, goal_x, goal_y, cli_proc_name)
          # IO.puts("robot b down")
          # IO.inspect(robot)
          get_goal(robot, goal_locs, i, reached_list, cli_proc_name, j)
        end
        # get_goal(robot, goal_locs, i, reached_list, cli_proc_name)
      end
    else
      sent_alt_statuss(robot,cli_proc_name,true)
  end
end

  def stop(robot, goal_locs, cli_proc_name) do

    get_goal(robot, goal_locs, 0, [], cli_proc_name, 0)
    # robot_returned = CLI.ToyRobotA.get_robot_a()
    # IO.puts("printing this from the file of robot b")
    # IO.inspect(robot_returned)
    # go_to_goal(%CLI.Position{x: x, y: y, facing: facing} = robot, goal_x, goal_y, cli_proc_name)
  end

  def check_for_obs(robot, cli_proc_name) do
    current = self()
    pid =
      spawn_link(fn ->
        x = send_robot_status(robot, cli_proc_name)
        send(current, x)
      end)
    Process.register(pid, :client_toyrobotB)
    receive do
      value -> value
    end
  end

  @doc """
  Provide GOAL positions to the robot as given location of [(x1, y1),(x2, y2),..] and plan the path from START to these locations.
  Passing the CLI Server process name that will be used to send robot's current status after each action is taken.
  Spawn a process and register it with name ':client_toyrobotB' which is used by CLI Server to send an
  indication for the presence of obstacle ahead of robot's current position and facing.
  """

  @doc """
  Send Toy Robot's current status i.e. location (x, y) and facing
  to the CLI Server process after each action is taken.
  Listen to the CLI Server and wait for the message indicating the presence of obstacle.
  The message with the format: '{:obstacle_presence, < true or false >}'.
  """
  def send_robot_status(%CLI.Position{x: x, y: y, facing: facing} = _robot, cli_proc_name) do
    send(cli_proc_name, {:toyrobotB_status, x, y, facing})
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

      iex> {:ok, robot} = CLI.ToyRobotB.place(2, :b, :west)
      iex> CLI.ToyRobotB.report(robot)
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
