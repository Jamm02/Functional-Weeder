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
      when facing not in [:north, :east, :south, :west] do
    {:failure, "Invalid facing direction"}
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

  ############################################################################ 3
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

  #################################################################################
  @doc """
  Provide START position to the robot as given location of (x, y, facing) and place it.
  """
  def start(x, y, facing) do
    {:ok, %ToyRobot.Position{x: x, y: y, facing: facing}}
  end

  def stop(_robot, goal_x, goal_y, _cli_proc_name)
      when goal_x < 1 or goal_y < :a or goal_x > @table_top_x or goal_y > @table_top_y do
    {:failure, "Invalid STOP position"}
  end

  @doc """
  Provide STOP position to the robot as given location of (x, y) and plan the path from START to STOP.
  Passing the CLI Server process name that will be used to send robot's current status after each action is taken.
  Spawn a process and register it with name ':client_toyrobot' which is used by CLI Server to send an
  indication for the presence of obstacle ahead of robot's current position and facing.
  """
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
    valid_x = [1,2,3,4,5]
    valid_y = [:a,:b,:c,:d,:e]
    Enum.member?(valid_x,x) and Enum.member?(valid_y,y)
  end

  # function to check the 4 successors(surrounding nodes to the parent node)
  def checkSuccessor(openList, closedList, nodeDetails, goal_x, goal_y, cli_proc_name) do
    # if the open list is empty return
    if(Enum.empty?(openList)) do
      {openList, closedList}
    else
      # remove the first cell form openList
      # this shoul be the node with least f so whenever a node is added to a open list in the upcoming code the list is sorted.
      current_node = Enum.at(openList, 0)
      # IO.inspect(node)
      openList = List.delete_at(openList, 0)
      # IO.puts("openList:")
      # IO.inspect(openList)

      # add it to closed list
      node_closed = %ClosedListStruct{x: current_node.x, y: current_node.y}
      closedList = [node_closed | closedList]
      IO.puts("closedList:")
      IO.inspect(closedList)

      ####################################################################################
      # TODO robot movement code here
      ####################################################################################
      # now check all the 4 surrounding nodes
      # x_p ==> x - coordinate of the parent node
      # y_p ==> y - coordinate of the parent node
      # ################   north   ############################
      x = find_successor_coordinates_x(current_node.x, :north)
      y = find_successor_coordinates_y(current_node.y, :north)
      # IO.puts("x: #{x} , y: #{y}")
      {nodeDetails,openList} = process_successor(openList, closedList, nodeDetails, goal_x, goal_y,current_node,x,y)

      # ################   east   ############################
      x = find_successor_coordinates_x(current_node.x, :east)
      y = find_successor_coordinates_y(current_node.y, :east)
      # IO.puts("x: #{x} , y: #{y}")
      {nodeDetails,openList} = process_successor(openList, closedList, nodeDetails, goal_x, goal_y,current_node,x,y)

      # ################   south   ############################
      x = find_successor_coordinates_x(current_node.x, :south)
      y = find_successor_coordinates_y(current_node.y, :south)
      # IO.puts("x: #{x} , y: #{y}")
      {nodeDetails,openList} = process_successor(openList, closedList, nodeDetails, goal_x, goal_y,current_node,x,y)

      # ################   west   ############################
      x = find_successor_coordinates_x(current_node.x, :west)
      y = find_successor_coordinates_y(current_node.y, :west)
      # IO.puts("x: #{x} , y: #{y}")
      {nodeDetails,openList} = process_successor(openList, closedList, nodeDetails, goal_x, goal_y,current_node,x,y)

      #########################recursive call##################################
      checkSuccessor(openList, closedList, nodeDetails, goal_x, goal_y, cli_proc_name)
    end
  end

  def process_successor(openList, closedList, nodeDetails, goal_x, goal_y,current_node,x,y) do
    %OpenListStruct{x: x_p, y: y_p, facing: facing, f: _f} = current_node
    {nodeDetails_return,openList_return} =
    if(is_valid(x,y) == false)do
      {:failure,"invalid coordinates"}
      nodeDetails_return = nodeDetails
      openList_return = openList
      {nodeDetails_return,openList_return}
    else
      {nodeDetails_return,openList_return} =
      if(goal_x == x and goal_y == y) do
        IO.puts("this successor is the destination")
        # Set the Parent of the destination cell and add it to the nodeDetails
        new_node_dest = %NodeDetailStruct{
          parent_x: x_p,
          parent_y: y_p,
          f: 10000.0,
          g: 10000.0,
          h: 10000.0
        }
        nodeDetails_return = modify(x, y, nodeDetails, new_node_dest)
        openList_return = openList
        {nodeDetails_return,openList_return}
      else
        successor_cell_closed = %ClosedListStruct{x: x, y: y}
        is_member_of_closed_list = list_check(closedList, successor_cell_closed)
        # IO.puts("x: #{x} , y: #{y}")
        {nodeDetails_return,openList_return} =
        if(is_member_of_closed_list == false) do
          node_new = acces(x, y, nodeDetails)
          parent_node = acces(x_p,y_p,nodeDetails)
          gNew = parent_node.g + 1.0
          hNew = calculate_h(x, y, goal_x, goal_y)
          fNew = gNew + hNew
          {nodeDetails_return,openList_return} =
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
            {nodeDetails_return,openList_return}
          end
          {nodeDetails_return,openList_return}
        else
          nodeDetails_return = nodeDetails
          openList_return = openList
        {nodeDetails_return,openList_return}
        end
      {nodeDetails_return,openList_return}
      end
    {nodeDetails_return,openList_return}
    end
  {nodeDetails_return,openList_return}
  end

  def create_grid_of_nodes do
    coll = List.duplicate(%NodeDetailStruct{}, 5)
    grid = List.duplicate(coll, 5)
  end

  def find_shortest_path(
        %ToyRobot.Position{x: x, y: y, facing: facing} = robot,
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

      checkSuccessor(opentList, closedList, nodeDetails, goal_x, goal_y, cli_proc_name)
    end
  end

  def stop(%ToyRobot.Position{x: x, y: y, facing: facing} = robot, goal_x, goal_y, cli_proc_name) do
    # grid = create_grid_of_nodes()
    # node = acces(3,:a,grid)
    # IO.inspect(node)
    # grid = modify(3,:a,grid,%NodeDetailStruct{parent_x: 1, parent_y: :a, f: 27.00, g: 54.0, h: 7.0})
    # node = acces(3,:a,grid)
    # IO.inspect(node)
    # x_s = find_successor_coordinates_x(2,:north)
    # y_s = find_successor_coordinates_y(:d,:north)
    # IO.inspect({x_s,y_s})
    find_shortest_path(robot, goal_x, goal_y, cli_proc_name)
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
    Process.register(pid, :client_toyrobot)
    receive do
      value -> value
    end
  end

  def send_robot_status(%ToyRobot.Position{x: x, y: y, facing: facing} = _robot, cli_proc_name) do
    send(cli_proc_name, {:toyrobot_status, x, y, facing})
    # IO.puts("Sent by Toy Robot Client: #{x}, #{y}, #{facing}")
    listen_from_server()
  end

  @doc """
  Listen to the CLI Server and wait for the message indicating the presence of obstacle.
  The message with the format: '{:obstacle_presence, < true or false >}'.
  """
  def listen_from_server() do
    receive do
      {:obstacle_presence, is_obs_ahead} -> is_obs_ahead
    end
  end

  @doc """
  Provides the report of the robot's current position

  Examples:

      iex> {:ok, robot} = ToyRobot.place(2, :b, :west)
      iex> ToyRobot.report(robot)
      {2, :b, :west}
  """
  def report(%ToyRobot.Position{x: x, y: y, facing: facing} = _robot) do
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
    %ToyRobot.Position{
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
  def move(%ToyRobot.Position{x: x, y: _, facing: :east} = robot) when x < @table_top_x do
    %ToyRobot.Position{robot | x: x + 1}
  end

  @doc """
  Moves the robot to the south, but prevents it to fall
  """
  def move(%ToyRobot.Position{x: _, y: y, facing: :south} = robot) when y > :a do
    %ToyRobot.Position{
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
