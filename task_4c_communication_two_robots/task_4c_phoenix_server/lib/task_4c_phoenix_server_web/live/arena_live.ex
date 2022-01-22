defmodule Task4CPhoenixServerWeb.ArenaLive do
  use Task4CPhoenixServerWeb,:live_view
  require Logger

  @doc """
  Mount the Dashboard when this module is called with request
  for the Arena view from the client like browser.
  Subscribe to the "robot:update" topic using Endpoint.
  Subscribe to the "timer:update" topic as PubSub.
  Assign default values to the variables which will be updated
  when new data arrives from the RobotChannel module.
  """
  def mount(_params, _session, socket) do

    Task4CPhoenixServerWeb.Endpoint.subscribe("robot:update")
    :ok = Phoenix.PubSub.subscribe(Task4CPhoenixServer.PubSub, "timer:update")
    # :ok = Phoenix.PubSub.subscribe(Task4CPhoenixServer.PubSub, "robot:position")

    socket = assign(socket, :img_robotA, "robot_facing_north.png")
    socket = assign(socket, :bottom_robotA, 0)
    socket = assign(socket, :left_robotA, 0)
    socket = assign(socket, :robotA_start, "")
    socket = assign(socket, :robotA_goals, [])

    socket = assign(socket, :img_robotB, "robot_facing_south.png")
    socket = assign(socket, :bottom_robotB, 750)
    socket = assign(socket, :left_robotB, 750)
    socket = assign(socket, :robotB_start, "")
    socket = assign(socket, :robotB_goals, [])

    socket = assign(socket, :obstacle_pos, MapSet.new())
    socket = assign(socket, :timer_tick, 300)

    {:ok,socket}

  end

  @doc """
  Render the Grid with the coordinates and robot's location based
  on the "img_robotA" or "img_robotB" variable assigned in the mount/3 function.
  This function will be dynamically called when there is a change
  in the values of any of these variables =>
  "img_robotA", "bottom_robotA", "left_robotA", "robotA_start", "robotA_goals",
  "img_robotB", "bottom_robotB", "left_robotB", "robotB_start", "robotB_goals",
  "obstacle_pos", "timer_tick"
  """
  def render(assigns) do

    ~H"""
    <div id="dashboard-container">

      <div class="grid-container">
        <div id="alphabets">
          <div> A </div>
          <div> B </div>
          <div> C </div>
          <div> D </div>
          <div> E </div>
          <div> F </div>
        </div>

        <div class="board-container">
          <div class="game-board">
            <div class="box"></div>
            <div class="box"></div>
            <div class="box"></div>
            <div class="box"></div>
            <div class="box"></div>
            <div class="box"></div>
            <div class="box"></div>
            <div class="box"></div>
            <div class="box"></div>
            <div class="box"></div>
            <div class="box"></div>
            <div class="box"></div>
            <div class="box"></div>
            <div class="box"></div>
            <div class="box"></div>
            <div class="box"></div>
            <div class="box"></div>
            <div class="box"></div>
            <div class="box"></div>
            <div class="box"></div>
            <div class="box"></div>
            <div class="box"></div>
            <div class="box"></div>
            <div class="box"></div>
            <div class="box"></div>
          </div>

          <%= for obs <- @obstacle_pos do %>
            <img  class="obstacles"  src="/images/stone.png" width="50px" style={"bottom: #{elem(obs,1)}px; left: #{elem(obs,0)}px"}>
          <% end %>

          <div class="robot-container" style={"bottom: #{@bottom_robotA}px; left: #{@left_robotA}px"}>
            <img id="robotA" src={"/images/#{@img_robotA}"} style="height:70px;">
          </div>

          <div class="robot-container" style={"bottom: #{@bottom_robotB}px; left: #{@left_robotB}px"}>
            <img id="robotB" src={"/images/#{@img_robotB}"} style="height:70px;">
          </div>

        </div>

        <div id="numbers">
          <div> 1 </div>
          <div> 2 </div>
          <div> 3 </div>
          <div> 4 </div>
          <div> 5 </div>
          <div> 6 </div>
        </div>

      </div>
      <div id="right-container">

        <div class="timer-card">
          <label style="text-transform:uppercase;width:100%;font-weight:bold;text-align:center" >Timer</label>
            <p id="timer" ><%= @timer_tick %></p>
        </div>

        <div class="goal-card">
          <div style="text-transform:uppercase;width:100%;font-weight:bold;text-align:center" > Goal positions </div>
          <div style="display:flex;flex-flow:wrap;width:100%">
            <div style="width:50%">
              <label>Robot A</label>
              <%= for i <- @robotA_goals do %>
                <div><%= i %></div>
              <% end %>
            </div>
            <div  style="width:50%">
              <label>Robot B</label>
              <%= for i <- @robotB_goals do %>
              <div><%= i %></div>
              <% end %>
            </div>
          </div>
        </div>

        <div class="position-card">
          <div style="text-transform:uppercase;width:100%;font-weight:bold;text-align:center"> Start Positions </div>
          <form phx-submit="start_clock" style="width:100%;display:flex;flex-flow:row wrap;">
            <div style="width:100%;padding:10px">
              <label>Robot A</label>
              <input name="robotA_start" style="background-color:white;" value={"#{@robotA_start}"}>
            </div>
            <div style="width:100%; padding:10px">
              <label>Robot B</label>
              <input name="robotB_start" style="background-color:white;" value={"#{@robotB_start}"}>
            </div>

            <button  id="start-btn" type="submit">
              <svg xmlns="http://www.w3.org/2000/svg" style="height:30px;width:30px;margin:auto" viewBox="0 0 20 20" fill="currentColor">
                <path fill-rule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zM9.555 7.168A1 1 0 008 8v4a1 1 0 001.555.832l3-2a1 1 0 000-1.664l-3-2z" clip-rule="evenodd" />
              </svg>
            </button>

            <button phx-click="stop_clock" id="stop-btn" type="button">
              <svg xmlns="http://www.w3.org/2000/svg" style="height:30px;width:30px;margin:auto" viewBox="0 0 20 20" fill="currentColor">
                <path fill-rule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zM8 7a1 1 0 00-1 1v4a1 1 0 001 1h4a1 1 0 001-1V8a1 1 0 00-1-1H8z" clip-rule="evenodd" />
              </svg>
            </button>
          </form>
        </div>

      </div>

    </div>
    """

  end

  @doc """
  Handle the event "start_clock" triggered by clicking
  the PLAY button on the dashboard.
  """
  def handle_event("start_clock", data, socket) do
    socket = assign(socket, :robotA_start, data["robotA_start"])
    socket = assign(socket, :robotB_start, data["robotB_start"])
    # Task4CPhoenixServerWeb.Endpoint.broadcast("timer:start", "start_timer", %{})
    # IO.inspect(data)
    goal_locs = make_goal_loc()
    data = Map.put(data,"goal_locs",goal_locs)
    # map = %{"face"=>Enum.at(str,2),"x" => Enum.at(str,0), "y"=> Enum.at(str,1)}
    # map_left_value_to_x = %{"1" => 0, "2" => 150, "3" => 300, "4" => 450, "5" => 600, "6" => 750}
    # map_bottom_value_to_y = %{"a" => 0, "b" => 150, "c" => 300, "d" => 450, "e" => 600, "f" => 750}
    # left_value = Map.get(map_left_value_to_x,map["x"])
    # bottom_value = Map.get(map_bottom_value_to_y, map["y"])
    # data = %{"client" => "robot_A", "left" => left_value, "bottom" => bottom_value, "face" =>  map["face"] }
    # Phoenix.PubSub.broadcast(Task4CPhoenixServer.PubSub, "robot:position", data)
    Task4CPhoenixServerWeb.Endpoint.broadcast("robot:get_position", "startPos", data)
    # IO.inspect(socket)
    {:noreply, socket}
  end

  @doc """
  Handle the event "stop_clock" triggered by clicking
  the STOP button on the dashboard.
  """
  def handle_event("stop_clock", _data, socket) do

    Task4CPhoenixServerWeb.Endpoint.broadcast("timer:stop", "stop_timer", %{})

    #################################
    ## edit the function if needed ##
    #################################

    {:noreply, socket}

  end

  @doc """
  Callback function to handle incoming data from the Timer module
  broadcasted on the "timer:update" topic.
  Assign the value to variable "timer_tick" for each countdown.
  """
  def handle_info(%{event: "update_timer_tick", payload: timer_data, topic: "timer:update"}, socket) do

    Logger.info("Timer tick: #{timer_data.time}")
    socket = assign(socket, :timer_tick, timer_data.time)

    {:noreply, socket}

  end

  @doc """
  Callback function to handle any incoming data from the RobotChannel module
  broadcasted on the "robot:update" topic.
  Assign the values to the variables => "img_robotA", "bottom_robotA", "left_robotA",
  "img_robotB", "bottom_robotB", "left_robotB" and "obstacle_pos" as received.
  Make sure to add a tuple of format: { < obstacle_x >, < obstacle_y > } to the MapSet object "obstacle_pos".
  These values msut be in pixels. You may handle these variables in separate callback functions as well.
  """
  def handle_info(data, socket) do
    # data = data.payload
    if (data["client"] == "robot_A") do
      cond do
        (data["face"] == "north")->
          socket = assign(socket, :img_robotA, "robot_facing_north.png")
        (data["face"]  == "south")->
          socket = assign(socket, :img_robotA, "robot_facing_south.png")
        (data["face"] == "east")->
          socket = assign(socket, :img_robotA, "robot_facing_east.png")
        (data["face"] == "west")->
          socket = assign(socket, :img_robotA, "robot_facing_.png")
      end
      socket = assign(socket, :bottom_robotA, data["bottom"])
      socket = assign(socket, :left_robotA, data["left"])
    end
    if (data["client"] == "robot_B") do
      cond do
        (data["face"] == "north")->
          socket = assign(socket, :img_robotB, "robot_facing_north.png")
        (data["face"]  == "south")->
          socket = assign(socket, :img_robotB, "robot_facing_south.png")
        (data["face"] == "east")->
          socket = assign(socket, :img_robotB, "robot_facing_east.png")
        (data["face"] == "west")->
          socket = assign(socket, :img_robotB, "robot_facing_.png")
      end
      socket = assign(socket, :bottom_robotB, data["bottom"])
      socket = assign(socket, :left_robotB, data["left"])
    end

    # socket = assign(socket, :robotA_goals, [])
    # socket = assign(socket, :robotB_goals, [])
    # socket = assign(socket, :obstacle_pos, MapSet.new())

    {:noreply, socket}

  end
  def make_goal_loc do
    csv =
      "~/Desktop/Functional-Weeder/task_4c_communication_two_robots/task_4c_phoenix_server/Plant_Positions.csv"
      |> Path.expand(__DIR__)
      |> File.stream!()
      |> CSV.decode(headers: true)
      |> Enum.map(fn data -> data end)
    list_of_goals = []
    goal_locs = make_list(csv,list_of_goals)
    # IO.inspect(goal_locs)
  end

  def make_list(csv,list_of_goals) do
    list_ret =
    if(Enum.empty?(csv)) do
      list_of_goals
    else
      map = Kernel.elem(Enum.at(csv,0),1)
      n1 = Map.get(map,"Sowing")
      n2 = Map.get(map,"Weeding")
      # list_of_goals = list_of_goals ++ get_goal(n1)
      # list_of_goals = list_of_goals ++ [List.to_tuple(get_goal(n1))]
      list_of_goals = list_of_goals ++ [get_goal(n1)]
      # IO.inspect(list_of_goals)
      # IO.inspect(get_goal(n1))
      # list_of_goals = list_of_goals ++ [List.to_tuple(get_goal(n2))]
      list_of_goals = list_of_goals ++ [get_goal(n2)]
      # list_of_goals = list_of_goals ++ get_goal(n2)
      # IO.inspect(list_of_goals)
      # IO.inspect(get_goal(n2))
      csv = List.delete_at(csv,0)
      make_list(csv,list_of_goals)
    end
    list_ret
  end
  def get_goal(n) do
    map = %{1 =>"a", 2 => "b", 3 => "c", 4 => "d", 5 => "e" , 6 => "f"}
    # if n>= 1 and n<=5 do
    #   x1 =to_string(n)
    #   # x2 =to_string(n+1)
    #   y1 =map[1]
    #   # y2 = map[2]
    #   #IO.puts "#{x1},#{x2},#{y1},#{y2}"
    #   # lst = [x1,y1,x1,y2,x2,y1,x2,y2]
    #   lst = [x1,y1]

    # else if n>=6 and n<=10 do
    #   x1 =to_string(n-5)
    #   # x2 =to_string(n-5+1)
    #   y1 =map[2]
    #   # y2 = map[3]
    #   # lst = [x1,y1,x1,y2,x2,y1,x2,y2]
    #   lst = [x1,y1]

    # else if n>=11 and n<=15 do
    #   x1 =to_string(n-10)
    #   # x2 =to_string(n-10+1)
    #   y1 =map[3]
    #   # y2 = map[4]
    #   # lst = [x1,y1,x1,y2,x2,y1,x2,y2]
    #   lst = [x1,y1]

    # else if n>=16 and n<=20 do
    #   x1 =to_string(n-15)
    #   # x2 =to_string(n-15+1)
    #   y1 =map[4]
    #   # y2 = map[5]
    #   lst = [x1,y1]
    #   # lst = [x1,y1,x1,y2,x2,y1,x2,y2]

    # else if n>=21 and n<=25 do
    #   x1 =to_string(n-20)
    #   # x2 =to_string(n-20+1)
    #   y1 = map[5]
    #   # y2 = map[6]
    #   # lst = [x1,y1,x1,y2,x2,y1,x2,y2]
    #   lst = [x1,y1]

    # end    # else if (4)
    # end   # else if (3)
    # end  # else if (2)

    # end # else if (1)
    # end # if
    n = String.to_integer(n)
    list =
    cond do
      n>= 1 and n<=5 ->
        x1 =to_string(n)
        # x2 =to_string(n+1)
        y1 =map[1]
        # y2 = map[2]
        #IO.puts "#{x1},#{x2},#{y1},#{y2}"
        # lst = [x1,y1,x1,y2,x2,y1,x2,y2]
        lst = [x1,y1]
      n>=6 and n<=10 ->
        x1 =to_string(n-5)
        # x2 =to_string(n-5+1)
        y1 =map[2]
        # y2 = map[3]
        # lst = [x1,y1,x1,y2,x2,y1,x2,y2]
        lst = [x1,y1]
      n>=11 and n<=15 ->
        x1 =to_string(n-10)
        # x2 =to_string(n-10+1)
        y1 =map[3]
        # y2 = map[4]
        # lst = [x1,y1,x1,y2,x2,y1,x2,y2]
        lst = [x1,y1]
      n>=16 and n<=20 ->
        x1 =to_string(n-15)
        # x2 =to_string(n-15+1)
        y1 =map[4]
        # y2 = map[5]
        lst = [x1,y1]
        # lst = [x1,y1,x1,y2,x2,y1,x2,y2]
      n>=21 and n<=25 ->
        x1 =to_string(n-20)
        # x2 =to_string(n-20+1)
        y1 = map[5]
        # y2 = map[6]
        # lst = [x1,y1,x1,y2,x2,y1,x2,y2]
        lst = [x1,y1]
    end
    list
  end
  ######################################################
  ## You may create extra helper functions as needed  ##
  ## and update remaining assign variables.           ##
  ######################################################

end
