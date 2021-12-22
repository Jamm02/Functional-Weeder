defmodule CLI.ToyRobotB do
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

      iex> CLI.ToyRobotB.place
      {:ok, %CLI.Position{facing: :north, x: 1, y: :a}}
  """
  def place do
    {:ok, %CLI.Position{}}
  end

  def place(x, y, _facing) when x < 1 or y < :a or x > @table_top_x or y > @table_top_y do
    {:failure, "Invalid position"}
  end

  def place(_x, _y, facing)
      when facing not in [:north, :east, :south, :west] do
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

  def start() do
    place()
  end

  def go_to_goal(_robot, goal_x, goal_y, _cli_proc_name)
      when goal_x < 1 or goal_y < :a or goal_x > @table_top_x or goal_y > @table_top_y do
    {:failure, "Invalid go_to_goal position"}
  end

  @doc """
  Provide GOAL positions to the robot as given location of [(x1, y1),(x2, y2),..] and plan the path from START to these locations.
  Passing the CLI Server process name that will be used to send robot's current status after each action is taken.
  Spawn a process and register it with name ':client_toyrobotB' which is used by CLI Server to send an
  indication for the presence of obstacle ahead of robot's current position and facing.
  """
  defmodule OpenListStruct do
    defstruct x: 1, y: :a, facing: :north, f: 0.0
  end

  # ClosedListStruct is a element of closed list that keep track of the nodes included in the path
  # it has fields of x: x-coordinate y: y-coordinate
  defmodule ClosedListStruct do
    defstruct x: 1, y: :a
  end

  # NodeDetailStruct is a struct that represents each node on a grid.
  defmodule NodeDetailStruct do
    defstruct parent_x: -1, parent_y: :z, f: 10000.0, g: 10000.0, h: 10000.0
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
      # new_list = Enum.sort(new_list, fn x, y -> x.value < y.value end)
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

  def give_A_info(%CLI.Position{x: x, y: y, facing: facing} = robot, goal_locs) do
    {:ok, pid} = Agent.start_link(fn -> %{} end)
    Process.register(pid, :your_map_name)
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

  def set_goal(
        a_data,
        b_data,
        i,
        goal_locs,
        %CLI.Position{x: x, y: y, facing: facing} = robot,
        cli_proc_name
      ) do
    # k = Enum.at(a_data, 0)
    # j = Enum.at(b_data, 0)
    # # if((k.value > j.value) and (k.index > j.index)) do
    #   goal_B = Enum.at(goal_locs, j.index)
    #   # IO.inspect(is_number(Enum.at(goal_B, 0)))
    #   {k, ""} = Integer.parse(Enum.at(goal_B, 0))

    #   j = String.to_atom(Enum.at(goal_B, 1))
    #   y_map_atom_to_int = %{:a => 1, :b => 2, :c => 3, :d => 4, :e => 5}
    #   j = y_map_atom_to_int[j]

    #   IO.inspect(is_number(j))
    #   goal_x = k
    #   goal_y = j
    #   go_to_goal(%CLI.Position{x: x, y: y, facing: facing} = robot, goal_x, goal_y, cli_proc_name)
    # # end
  end
  def robot_movement(robot, final_cordinates,cli_proc_name, counter) do
    counter = counter + 1
    %CLI.Position{x: x, y: y, facing: facing} = robot
    # IO.inspect(robot)
    # IO.inspect(final_cordinates)
    facing_ret =
    cond do
      final_cordinates.x > x and y == final_cordinates.y ->
        facing_ret =
          cond do
          facing == :north->
            robot = right(robot)
            is_obs = check_for_obs(robot,cli_proc_name)
            robot = move(robot)
            is_obs = check_for_obs(robot,cli_proc_name)
            facing_ret = robot.facing
          facing == :south->
            robot = left(robot)
            is_obs = check_for_obs(robot,cli_proc_name)
            robot = move(robot)
            is_obs = check_for_obs(robot,cli_proc_name)
            facing_ret = robot.facing
          facing == :west ->
            robot = right(robot)
            is_obs = check_for_obs(robot,cli_proc_name)
            robot = right(robot)
            is_obs = check_for_obs(robot,cli_proc_name)
            robot = move(robot)
            is_obs = check_for_obs(robot,cli_proc_name)
            facing_ret = robot.facing
          facing == :east ->
            robot = move(robot)
            is_obs = check_for_obs(robot,cli_proc_name)
            facing_ret = robot.facing
        end

      final_cordinates.x < x and y == final_cordinates.y ->
        facing_ret =
          cond do
            facing == :north->
              robot = left(robot)
              is_obs = check_for_obs(robot,cli_proc_name)
              robot = move(robot)
              is_obs = check_for_obs(robot,cli_proc_name)
              facing_ret = robot.facing
            facing == :south->
              robot = right(robot)
              is_obs = check_for_obs(robot,cli_proc_name)
              robot = move(robot)
              is_obs = check_for_obs(robot,cli_proc_name)
              facing_ret = robot.facing
            facing == :east ->
              robot = right(robot)
              is_obs = check_for_obs(robot,cli_proc_name)
              robot = right(robot)
              is_obs = check_for_obs(robot,cli_proc_name)
              robot = move(robot)
              is_obs = check_for_obs(robot,cli_proc_name)
              facing_ret = robot.facing
            facing == :west ->
              robot = move(robot)
              is_obs = check_for_obs(robot,cli_proc_name)
              facing_ret = robot.facing
          end
      final_cordinates.y > y and x == final_cordinates.x ->
        facing_ret =
          cond do
            facing == :north->
              robot = move(robot)
              is_obs = check_for_obs(robot,cli_proc_name)
              facing_ret = robot.facing
            facing == :south->
              robot = right(robot)
              is_obs = check_for_obs(robot,cli_proc_name)
              robot = right(robot)
              is_obs = check_for_obs(robot,cli_proc_name)
              robot = move(robot)
              is_obs = check_for_obs(robot,cli_proc_name)
              facing_ret = robot.facing
            facing == :east ->
              robot = left(robot)
              is_obs = check_for_obs(robot,cli_proc_name)
              robot = move(robot)
              is_obs = check_for_obs(robot,cli_proc_name)
              facing_ret = robot.facing
            facing == :west ->
              robot = right(robot)
              is_obs = check_for_obs(robot,cli_proc_name)
              robot = move(robot)
              is_obs = check_for_obs(robot,cli_proc_name)
              facing_ret = robot.facing
          end

        final_cordinates.y < y and x == final_cordinates.x ->
          facing_ret =
            cond do

              facing == :north->
                robot = right(robot)
                is_obs = check_for_obs(robot,cli_proc_name)
                robot = right(robot)
                is_obs = check_for_obs(robot,cli_proc_name)
                robot = move(robot)
                is_obs = check_for_obs(robot,cli_proc_name)
                facing_ret = robot.facing
              facing == :south->
                robot = move(robot)
                is_obs = check_for_obs(robot,cli_proc_name)
                facing_ret = robot.facing
              facing == :east ->
                robot = right(robot)
                is_obs = check_for_obs(robot,cli_proc_name)
                robot = move(robot)
                is_obs = check_for_obs(robot,cli_proc_name)
                facing_ret = robot.facing
              facing == :west ->
                robot = left(robot)
                is_obs = check_for_obs(robot,cli_proc_name)
                robot = move(robot)
                is_obs = check_for_obs(robot,cli_proc_name)
                facing_ret = robot.facing
            end
    end
    {facing_ret,counter}
  end
  def find_successor_coordinates_x(x, facing) do
    x_result =
      cond do
        facing == :east -> x + 1
        facing == :west -> x - 1
        facing == :north -> x
        facing == :south -> x
      end
  end

  # finds the y coordinate of the successor according to its facing
  def find_successor_coordinates_y(y, facing) do
    y_map_atom_to_int = %{:a => 1, :b => 2, :c => 3, :d => 4, :e => 5}
    y_int = y_map_atom_to_int[y]

    y_result =
      cond do
        facing == :east -> y_int
        facing == :west -> y_int
        facing == :north -> y_int + 1
        facing == :south -> y_int - 1
      end

    y_map_int_to_atom = %{0 => :z, 1 => :a, 2 => :b, 3 => :c, 4 => :d, 5 => :e, 6 => :f}
    y_final = y_map_int_to_atom[y_result]
  end

  # function to sort the list according to the f value (accending)
  def sort_list(list) do
    list_new = Enum.sort(list, fn x, y -> x.f < y.f end)
  end

  # function to calculate the hueristic value of h(euclidian path)
  def calculate_h(x, y, goal_x, goal_y) do
    y_map_atom_to_int = %{:a => 1, :b => 2, :c => 3, :d => 4, :e => 5}
    dx = goal_x - x
    dy = y_map_atom_to_int[goal_y] - y_map_atom_to_int[y]
    sq_dist = dx * dx + dy * dy
    :math.sqrt(sq_dist)
  end

  # checks if the node is present in the list
  def list_check(list, cell) do
    if(Enum.empty?(list) == false) do
      is_member = Enum.member?(list, cell)
    end
  end

  # to access the membets of the nodeDetails list(2d list)
  def acces(x, y, grid) do
    y_cord =
      cond do
        y == :a -> 1
        y == :b -> 2
        y == :c -> 3
        y == :d -> 4
        y == :e -> 5
      end

    coll = Enum.at(grid, x - 1)
    node = Enum.at(coll, y_cord - 1)
  end

  # to modify the membets of the nodeDetails list(2d list)
  def modify(x, y, grid, node) do
    y_cord =
      cond do
        y == :a -> 1
        y == :b -> 2
        y == :c -> 3
        y == :d -> 4
        y == :e -> 5
      end

    coll = Enum.at(grid, x - 1)
    coll = List.replace_at(coll, y_cord - 1, node)
    grid_ret = List.replace_at(grid, x - 1, coll)
  end

  # function to check if the x and y coordinates are valid according to the constarains of the grid size and value
  def is_valid(x, y) do
    valid_x = [1, 2, 3, 4, 5]
    valid_y = [:a, :b, :c, :d, :e]
    Enum.member?(valid_x, x) and Enum.member?(valid_y, y)
  end

  def checkSuccessor(openList, closedList, nodeDetails, goal_x, goal_y, cli_proc_name,goal_reached,facing_ret,counter) do
    # if the open list is empty return
    if(Enum.empty?(openList) or goal_reached == true) do
      destination = Enum.at(openList, 0)
      robot = %CLI.Position{x: destination.x, y: destination.y, facing: destination.facing}
      is_obs = check_for_obs(robot,cli_proc_name)
      {:ok, robot}
    else
      # remove the first cell form openList
      # this shoul be the node with least f so whenever a node is added to a open list in the upcoming code the list is sorted.
      open_list_node_1 = Enum.at(openList, 0)
      # IO.puts("openList:")
      # IO.inspect(openList)
      openList = List.delete_at(openList, 0)
      # add it to closed list
      node_closed = %ClosedListStruct{x: open_list_node_1.x, y: open_list_node_1.y}
      closedList = [node_closed | closedList]
      # IO.puts("closedList: ")
      # IO.inspect(closedList)
      {facing_ret,counter} =
      if (Enum.count(closedList) > 1) do
        closed_list_node_0 = Enum.at(closedList,0)
        closed_list_node_1 = Enum.at(closedList,1)
        robot_i = %CLI.Position{
          x: closed_list_node_1.x,
          y: closed_list_node_1.y,
          facing: facing_ret
        }
        final_coordinates = %{x: closed_list_node_0.x, y: closed_list_node_0.y}
        {facing_ret,counter} = robot_movement(robot_i, final_coordinates, cli_proc_name,counter)
        # IO.puts("-----------------------------------------------------------------------------------")
        # IO.inspect(facing_ret)
        # IO.puts("-----------------------------------------------------------------------------------")
        {facing_ret,counter}
        else
        closed_list_node_0 = Enum.at(closedList,0)
        robot_spawn_loc = %CLI.Position{
          x: closed_list_node_0.x,
          y: closed_list_node_0.y,
          facing: open_list_node_1.facing
        }
        is_obs = check_for_obs(robot_spawn_loc,cli_proc_name)
        facing_ret = robot_spawn_loc.facing
        {facing_ret,counter}
      end
      openList = []
      # now check all the 4 surrounding nodes
      # x_p ==> x - coordinate of the parent node
      # y_p ==> y - coordinate of the parent node
      is_dest = false
      # ################   north   ############################
      x = find_successor_coordinates_x(open_list_node_1.x, :north)
      y = find_successor_coordinates_y(open_list_node_1.y, :north)
      # IO.puts("x: #{x} , y: #{y}")
      {nodeDetails, openList, is_dest} =
        if(is_dest == false) do
          {nodeDetails,openList,is_dest} = process_successor(openList, closedList, nodeDetails, goal_x, goal_y,open_list_node_1,x,y)
          # IO.puts("checked north")
          # IO.puts("destionation reached : #{is_dest}")
          {nodeDetails, openList, is_dest}
        else
          {nodeDetails, openList, is_dest}
        end
      # IO.puts("now checking successors")
      # ################   east   ############################
      x = find_successor_coordinates_x(open_list_node_1.x, :east)
      y = find_successor_coordinates_y(open_list_node_1.y, :east)
      # IO.puts("x: #{x} , y: #{y}")
      {nodeDetails, openList, is_dest} =
        if(is_dest == false) do
          {nodeDetails,openList,is_dest} = process_successor(openList, closedList, nodeDetails, goal_x, goal_y,open_list_node_1,x,y)

          # IO.puts("checked east")
          # IO.puts("destionation reached : #{is_dest}")
          {nodeDetails, openList, is_dest}
        else
          {nodeDetails, openList, is_dest}
        end

      # ################   south   ############################
      x = find_successor_coordinates_x(open_list_node_1.x, :south)
      y = find_successor_coordinates_y(open_list_node_1.y, :south)
      # IO.puts("x: #{x} , y: #{y}")
      {nodeDetails, openList, is_dest} =
        if is_dest == false do
          {nodeDetails,openList,is_dest} = process_successor(openList, closedList, nodeDetails, goal_x, goal_y,open_list_node_1,x,y)

          # IO.puts("checked south")
          # IO.puts("destionation reached : #{is_dest}")
          {nodeDetails, openList, is_dest}
        else
          {nodeDetails, openList, is_dest}
        end

      # ################   west   ############################
      x = find_successor_coordinates_x(open_list_node_1.x, :west)
      y = find_successor_coordinates_y(open_list_node_1.y, :west)
      # IO.puts("x: #{x} , y: #{y}")
      {nodeDetails, openList, is_dest} =
        if is_dest == false do
          {nodeDetails,openList,is_dest} = process_successor(openList, closedList, nodeDetails, goal_x, goal_y,open_list_node_1,x,y)

          # IO.puts("checked west")
          # IO.puts("destionation reached : #{is_dest}")
          {nodeDetails, openList, is_dest}
        else
          {nodeDetails, openList, is_dest}
        end
      ######################### recursive call##################################

      checkSuccessor(openList, closedList, nodeDetails, goal_x, goal_y, cli_proc_name, is_dest, facing_ret,counter)
    end
  end


  def process_successor(openList, closedList, nodeDetails, goal_x, goal_y, current_node, x, y) do
    is_dest_reached = false
    %OpenListStruct{x: x_p, y: y_p, facing: facing, f: _f} = current_node
    ## [1]
    ### if 1####
    ### else 1 ###
    {nodeDetails_return, openList_return, is_dest_reached} =
      if(is_valid(x, y) == false) do
        {:failure, "invalid coordinates"}
        nodeDetails_return = nodeDetails
        openList_return = openList
        ### return if 1 #####   [1]
        {nodeDetails_return, openList_return, is_dest_reached}
      else
        ## [2]
        ### if 2 ###
        #### else 2 ###
        {nodeDetails_return, openList_return, is_dest_reached} =
          if(goal_x == x and goal_y == y) do
            # IO.puts("this successor is the destination")
            # Set the Parent of the destination cell and add it to the nodeDetails
            new_node_dest = %NodeDetailStruct{
              parent_x: x_p,
              parent_y: y_p,
              f: 10000.0,
              g: 10000.0,
              h: 10000.0
            }

            nodeDetails_return = modify(x, y, nodeDetails, new_node_dest)
            destination = %OpenListStruct{x: x, y: y, facing: facing, f: 0.0}
            openList_return = [destination | openList]
            is_dest_reached = true
            ### return if 2 ####   [2]
            {nodeDetails_return, openList_return, is_dest_reached}
          else
            # IO.puts("reached here ........................")
            successor_cell_closed = %ClosedListStruct{x: x, y: y}
            is_member_of_closed_list = list_check(closedList, successor_cell_closed)
            # IO.puts("x: #{x} , y: #{y}")
            ## [3]
            #### if 3 ####
            #### else 3 ######
            {nodeDetails_return, openList_return, is_dest_reached} =
              if(is_member_of_closed_list == false) do
                node_new = acces(x, y, nodeDetails)
                parent_node = acces(x_p, y_p, nodeDetails)

                gNew = parent_node.g + 1.0
                hNew = calculate_h(x, y, goal_x, goal_y)
                fNew = gNew + hNew

                ## [4]
                #### if 4 ####
                {nodeDetails_return, openList_return, is_dest_reached} =
                  if(node_new.f == 10000.0 or node_new.f > fNew) do
                    # add the cell to open list
                    x_i = x_p
                    x_f = x
                    y_map_atom_to_int = %{:a => 1, :b => 2, :c => 3, :d => 4, :e => 5}
                    y_i = y_map_atom_to_int[y_p]
                    y_f = y_map_atom_to_int[y]
                    # IO.puts("final x : #{x_f} and final y : #{y_f}")
                    # IO.puts("initial x : #{x_i} and initial y : #{y_i}")
                    facing =
                      cond do
                        x_f > x_i and y_f == y_i ->
                          :east
                        x_f < x_i and y_f == y_i ->
                          :west
                        y_f > y_i and x_f == x_i ->
                          :north
                        y_f < y_i and x_f == x_i ->
                          :south
                      end
                    cell_to_insert = %OpenListStruct{x: x, y: y, facing: facing, f: fNew}
                    openList = [cell_to_insert | openList]
                    # sort the list so that the cell with lowest f is in the begining
                    openList = sort_list(openList)
                    # update the details of this node
                    new_node_successor = %NodeDetailStruct{
                      parent_x: x_p,
                      parent_y: y_p,
                      f: fNew,
                      g: gNew,
                      h: hNew
                    }

                    nodeDetails_return = modify(x, y, nodeDetails, new_node_successor)
                    openList_return = openList
                    ### return if 4 ###   [4]
                    {nodeDetails_return, openList_return, is_dest_reached}
                  else
                    nodeDetails_return = nodeDetails
                    openList_return = openList
                    {nodeDetails_return, openList_return, is_dest_reached}
                  end

                ### return if 3 ###
                {nodeDetails_return, openList_return, is_dest_reached}
              else
                nodeDetails_return = nodeDetails
                openList_return = openList
                ### return else 3 #### [3]
                {nodeDetails_return, openList_return, is_dest_reached}
              end

            ### return else 2 ##      [2]
            {nodeDetails_return, openList_return, is_dest_reached}
          end

        ### return else 1 ###  [1]
        {nodeDetails_return, openList_return, is_dest_reached}
      end

    {nodeDetails_return, openList_return, is_dest_reached}
  end

  def create_grid_of_nodes do
    coll = List.duplicate(%NodeDetailStruct{}, 5)
    grid = List.duplicate(coll, 5)
  end

  def find_shortest_path(
        %CLI.Position{x: x, y: y, facing: facing} = robot,
        goal_x,
        goal_y,
        cli_proc_name
      ) do
    # check if the destination has been reached
    if(x == goal_x and y == goal_y) do
      {:ok, robot}
    else
      # make and initialize the ClosedList
      closedList = []

      # make and initialize the node details list
      nodeDetails = create_grid_of_nodes()

      # Initialising the parameters of the starting node
      start_node = %NodeDetailStruct{parent_x: x, parent_y: y, f: 0.0, g: 0.0, h: 0.0}
      nodeDetails = modify(x, y, nodeDetails, start_node)
      # IO.inspect(nodeDetails)

      # make and initialize the opentlist
      opentList = []

      # put the starting cell on the openList
      start_cell_on_list = %OpenListStruct{x: x, y: y, facing: facing, f: 0.0}
      opentList = [start_cell_on_list | opentList]
      # IO.inspect(opentList)
      goal_reached = false
      facing_ret = facing
      counter = 0
      checkSuccessor(opentList, closedList, nodeDetails, goal_x, goal_y, cli_proc_name,goal_reached,facing_ret,counter)
    end
  end

  def stop(%CLI.Position{x: x, y: y, facing: facing} = robot, goal_locs, cli_proc_name) do
    give_A_info(robot, goal_locs)
    a_data = get_A()
    index_list = []
    dist_list = []

    b_data =
      dist(%CLI.Position{x: x, y: y, facing: facing} = robot, goal_locs, 0, index_list, dist_list)

    # IO.inspect(a_data)
    # IO.inspect(goal_locs)
    goal_x = String.to_integer(Enum.at(Enum.at(goal_locs, 0), 0))
    goal_y = String.to_atom(Enum.at(Enum.at(goal_locs, 0), 1))
    # IO.inspect(goal_x)
    # IO.inspect(goal_y)
    find_shortest_path(robot, goal_x, goal_y, cli_proc_name)

    # set_goal(a_data, b_data, 0 , goal_locs, %CLI.Position{x: x, y: y, facing: facing} = robot, cli_proc_name)
  end

  @doc """
  Send Toy Robot's current status i.e. location (x, y) and facing
  to the CLI Server process after each action is taken.
  Listen to the CLI Server and wait for the message indicating the presence of obstacle.
  The message with the format: '{:obstacle_presence, < true or false >}'.
  """
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
    %CLI.Position{
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
  def move(%CLI.Position{x: x, y: _, facing: :east} = robot) when x < @table_top_x do
    %CLI.Position{robot | x: x + 1}
  end

  @doc """
  Moves the robot to the south, but prevents it to fall
  """
  def move(%CLI.Position{x: _, y: y, facing: :south} = robot) when y > :a do
    %CLI.Position{
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
