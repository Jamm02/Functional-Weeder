defmodule Task4CPhoenixServerWeb.RobotChannel do
  use Phoenix.Channel

  @doc """
  Handler function for any Client joining the channel with topic "robot:status".
  Subscribe to the topic named "robot:update" on the Phoenix Server using Endpoint.
  Reply or Acknowledge with socket PID received from the Client.
  """
  def join("robot:status", _params, socket) do
    Task4CPhoenixServerWeb.Endpoint.subscribe("robot:update")
    {:ok, socket}
  end

  def join("robot:position", _params, socket) do
    Task4CPhoenixServerWeb.Endpoint.subscribe("robot:get_position")
    {:ok, socket}
  end

  @doc """
  Callback function for messages that are pushed to the channel with "robot:status" topic with an event named "new_msg".
  Receive the message from the Client, parse it to create another Map strictly of this format:
  %{"client" => < "robot_A" or "robot_B" >,  "left" => < left_value >, "bottom" => < bottom_value >, "face" => < face_value > }

  These values should be pixel locations for the robot's image to be displayed on the Dashboard
  corresponding to the various actions of the robot as recevied from the Client.

  Broadcast the created Map of pixel locations, so that the ArenaLive module can update
  the robot's image and location on the Dashboard as soon as it receives the new data.

  Based on the message from the Client, determine the obstacle's presence in front of the robot
  and return the boolean value in this format {:ok, < true OR false >}.

  If an obstacle is present ahead of the robot, then broadcast the pixel location of the obstacle to be displayed on the Dashboard.
  """

  def handle_in("new_msg", message, socket) do
    is_obs_ahead =
      Task4CPhoenixServerWeb.FindObstaclePresence.is_obstacle_ahead?(
        message["x"],
        message["y"],
        message["face"]
      )

    {:ok, out_file} = File.open("task_4c_output.txt", [:append])

    IO.binwrite(
      out_file,
      "#{message["client"]} => #{message["x"]}, #{message["y"]}, #{message["face"]}\n"
    )

    # IO.inspect(message)
    # %{"client" => "robot_A", "face" => "north", "x" => 2, "y" => "b"}
    # if message["client"] == "robot_A" do
    #   IO.puts("enterred here")
    #   socket = assign(socket,:robot_A,%{x: message["x"], y: message["y"], facing: message["face"]})
    # end

    # if message["client"] == "robot_B" do
    #   socket = assign(socket,:robot_B,%{x: message["x"], y: message["y"], facing: message["face"]})
    # end
    # IO.inspect(socket)
    map_left_value_to_x = %{1 => 0, 2 => 150, 3 => 300, 4 => 450, 5 => 600, 6 => 750}

    map_bottom_value_to_y = %{
      "a" => 0,
      "b" => 150,
      "c" => 300,
      "d" => 450,
      "e" => 600,
      "f" => 750
    }

    left_value = Map.get(map_left_value_to_x, message["x"])
    bottom_value = Map.get(map_bottom_value_to_y, message["y"])

    data =
      if is_obs_ahead == false do
        data = %{
          "client" => message["client"],
          "left" => left_value,
          "bottom" => bottom_value,
          "face" => message["face"]
        }
      else
        data = %{
          "obs" => "true",
          "left" => left_value,
          "bottom" => bottom_value,
          "face" => message["face"]
        }
      end

    Phoenix.PubSub.broadcast(Task4CPhoenixServer.PubSub, "robot:update", data)
    # Task4CPhoenixServerWeb.Endpoint.broadcast("robot:update","", data)
    {:reply, {:ok, is_obs_ahead}, socket}
  end

  # callback invoked when message is pushed from the robot client.
  def handle_in("give_start_posa", _message, socket) do
    # wait_for_arena_live(message)
    # socket = assign(socket, :robota_start_pos,message)
    position =
      if Map.has_key?(socket.assigns, :robota_start_pos) == false do
        position = "start pos not recived"
      else
        position = socket.assigns.robota_start_pos
      end

    {:reply, {:ok, position}, socket}
  end

  def handle_in("give_start_posb", _message, socket) do
    # wait_for_arena_live(message)
    # socket = assign(socket, :robota_start_pos,message)
    position =
      if Map.has_key?(socket.assigns, :robotb_start_pos) == false do
        position = "start pos not recived"
      else
        position = socket.assigns.robotb_start_pos
      end

    {:reply, {:ok, position}, socket}
  end

  def handle_in("give_goal_loc", _message, socket) do
    # wait_for_arena_live(message)
    # socket = assign(socket, :robota_start_pos,message)
    position =
      if Map.has_key?(socket.assigns, :goal_locs) == false do
        position = "goal pos not recived"
      else
        position = socket.assigns.goal_locs
      end

    {:reply, {:ok, position}, socket}
  end

  # def handle_in("robot_a_pos_update", message, socket) do
  #   # wait_for_arena_live(message)
  #   # socket = assign(socket, :robota_start_pos,message)
  #   # position =
  #   # if Map.has_key?(socket.assigns,:goal_locs) == false do
  #   #   position = "goal pos not recived"
  #   # else
  #   #   position = socket.assigns.goal_locs
  #   # end
  #   reply = "position updated"
  #   socket = assign(socket,:robot_A_pos,message)
  #   {:reply, {:ok, reply}, socket}
  # end

  # def handle_in("robot_b_pos_update", message, socket) do
  #   reply = "position updated"
  #   socket = assign(socket,:robot_B_pos,message)
  #   {:reply, {:ok, reply}, socket}
  # end

  ################################################ from robot a for goal distribution #####################################################################
  # update callback for a_data
  def handle_in("update_a_data", a_data, socket) do
    reply = "a_data updated"
    # IO.inspect(a_data)
    socket = assign(socket, :give_info_A, a_data)

    Task4CPhoenixServerWeb.Endpoint.broadcast(
      "robot:get_position",
      "update_data",
      {:give_info_A, a_data}
    )

    # IO.inspect(socket)
    {:reply, {:ok, reply}, socket}
  end

  # update callback for visited index list
  def handle_in("update_visited_index", visited_index, socket) do
    reply = "indexes updated"
    socket = assign(socket, :indexes, visited_index)

    Task4CPhoenixServerWeb.Endpoint.broadcast(
      "robot:get_position",
      "update_data",
      {:indexes, visited_index}
    )

    {:reply, {:ok, reply}, socket}
  end

  # get callback for robot_b position
  def handle_in("getPosB", _message, socket) do
    # IO.inspect(socket)
    reply =
      if Map.has_key?(socket.assigns, :robotB) == false do
        position = "robot b pos not recived"
      else
        position = socket.assigns.robotB
      end

    ######################################################################
    # TODO
    ######################################################################
    {:reply, {:ok, reply}, socket}
  end

  ################################################ from robot a #####################################################################

  ################################################## from robot_b ################################################################
  # update callback for robot b position
  def handle_in("update_robot_b", final_data, socket) do
    reply = "updated robot b"
    # socket = assign(socket,:robotB,final_data)
    Task4CPhoenixServerWeb.Endpoint.broadcast(
      "robot:get_position",
      "update_data",
      {:robotB, final_data}
    )

    # IO.inspect(socket)
    {:reply, {:ok, reply}, socket}
  end

  # get callback for a_data
  def handle_in("get_a_data", _message, socket) do
    # reply = socket.assigns.give_info_A
    # IO.puts("handle in clalback of the get_a_data callback to see the socket")
    # IO.inspect(socket)
    reply =
      if Map.has_key?(socket.assigns, :give_info_A) == false do
        "a_data not recived"
      else
        a_data = socket.assigns.give_info_A

      end

    {:reply, {:ok, reply}, socket}
  end

  # get callback for index ist
  def handle_in("get_index_list", _message, socket) do
    # reply = socket.assigns.indexes
    reply =
      if Map.has_key?(socket.assigns, :indexes) == false do
        position = "index list not recived"
      else
        position = socket.assigns.indexes
      end

    {:reply, {:ok, reply}, socket}
  end

  ################################################## from robot_b ################################################################
  ################################################ from robot a for goal distribution ############################################

  def handle_in("give_robot_b_pos", _message, socket) do
    robot_b_pos = socket.assigns.robot_B_pos
    {:reply, {:ok, robot_b_pos}, socket}
  end

  def handle_in("give_robot_a_pos", _message, socket) do
    robot_a_pos = socket.assigns.robot_A_pos
    {:reply, {:ok, robot_a_pos}, socket}
  end

  # callback invoked when start positions are broadcasted from the areana live module
  def handle_info(%{event: "startPos", payload: data}, socket) do
    socket = assign(socket, :robota_start_pos, data["robotA_start"])
    socket = assign(socket, :robotb_start_pos, data["robotB_start"])
    socket = assign(socket, :goal_locs, data["goal_locs"])
    # socket with the robot:position
    # IO.inspect(socket)
    {:noreply, socket}
  end

  def handle_info(%{event: "update_data", payload: {key, value}}, socket) do
    # IO.inspect(socket)
    socket = assign(socket, key, value)
    {:noreply, socket}
  end

  def handle_info(msg, socket) do
    ######################################
    {:noreply, socket}
  end

  #########################################
  ## define callback functions as needed ##
  #########################################
end
