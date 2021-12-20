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
      when facing not in [:north, :east, :south, :west] do
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

  def stop(_robot, goal_x, goal_y, _cli_proc_name)
      when goal_x < 1 or goal_y < :a or goal_x > @table_top_x or goal_y > @table_top_y do
    {:failure, "Invalid STOP position"}
  end

  @doc """
  Provide GOAL positions to the robot as given location of [(x1, y1),(x2, y2),..] and plan the path from START to these locations.
  Passing the CLI Server process name that will be used to send robot's current status after each action is taken.
  Spawn a process and register it with name ':client_toyrobotA' which is used by CLI Server to send an
  indication for the presence of obstacle ahead of robot's current position and facing.
  """
  # OpenListStruct is the elemetn of Oen list which will stort the successors that are to be evalluated.
  # it has fields of x: x-coordinate y: y-coordinate facing: robots's facint f:the cost of that particular node
  # Structs in elixir has same name as the module in which it is defined usnig defstruct construct.
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


  def get_posB() do
    Process.sleep(10)
    Agent.get(:your_map_name, fn map -> Map.get(map, :robotB) end)
  end


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

      if(k.value <= j.value and k.index <= j.index) do
        goal_A = Enum.at(goal_locs, k.index)
        # go_to_goal(goal_A)
      end
    end
  end
  def robot_movement(robot, final_cordinates,cli_proc_name) do
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
                IO.puts(" Bharosa rakh bhai:  idhar tak pohoch gaya hai")
                robot = left(robot)
                is_obs = check_for_obs(robot,cli_proc_name)
                robot = move(robot)
                is_obs = check_for_obs(robot,cli_proc_name)
                facing_ret = robot.facing
            end
    end
    facing_ret
  end
  # finds the x coordinate of the successor according to its facing
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

  def checkSuccessor(openList, closedList, nodeDetails, goal_x, goal_y, cli_proc_name,goal_reached,facing_ret) do
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
      facing = open_list_node_1.facing
      # IO.puts("openList:")
      # IO.inspect(openList)
      openList = List.delete_at(openList, 0)
      # add it to closed list
      node_closed = %ClosedListStruct{x: open_list_node_1.x, y: open_list_node_1.y}
      closedList = [node_closed | closedList]
      # IO.puts("closedList: ")
      # IO.inspect(closedList)
      facing_ret =
      if (Enum.count(closedList) > 1) do
        closed_list_node_0 = Enum.at(closedList,0)
        closed_list_node_1 = Enum.at(closedList,1)
        robot_i = %CLI.Position{
          x: closed_list_node_1.x,
          y: closed_list_node_1.y,
          facing: facing_ret
        }
        final_coordinates = %{x: closed_list_node_0.x, y: closed_list_node_0.y}
        facing_ret = robot_movement(robot_i, final_coordinates, cli_proc_name)
        # IO.puts("-----------------------------------------------------------------------------------")
        # IO.inspect(facing_ret)
        # IO.puts("-----------------------------------------------------------------------------------")
        facing_ret
        else
        closed_list_node_0 = Enum.at(closedList,0)
        robot_spawn_loc = %CLI.Position{
          x: closed_list_node_0.x,
          y: closed_list_node_0.y,
          facing: open_list_node_1.facing
        }
        is_obs = check_for_obs(robot_spawn_loc,cli_proc_name)
        robot_spawn_loc.facing
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
      checkSuccessor(openList, closedList, nodeDetails, goal_x, goal_y, cli_proc_name, is_dest,facing_ret)
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
      checkSuccessor(opentList, closedList, nodeDetails, goal_x, goal_y, cli_proc_name,goal_reached,facing_ret)
    end
  end

  def stop(%CLI.Position{x: x, y: y, facing: facing} = robot, goal_locs, cli_proc_name) do
    index_list = []
    dist_list = []

    a_data =
      dist(%CLI.Position{x: x, y: y, facing: facing} = robot, goal_locs, 0, index_list, dist_list)

    b_data = sort_B()
    give_A(a_data)
    # set_goal(a_data, b_data, 0, goal_locs)
    # IO.inspect(b_data)
    goal_x = String.to_integer(Enum.at(Enum.at(goal_locs, 0), 0))
    goal_y = String.to_atom(Enum.at(Enum.at(goal_locs, 0), 1))
    # IO.inspect(goal_x)
    # IO.inspect(goal_y)
    find_shortest_path(robot, goal_x, goal_y, cli_proc_name)
  end
  def check_for_obs(robot, cli_proc_name) do
    current = self()
    pid =
      spawn_link(fn ->
        x = send_robot_status(robot, cli_proc_name)
        send(current, x)
      end)
    Process.register(pid, :client_toyrobotA)
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
