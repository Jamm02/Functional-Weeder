defmodule Task4CPhoenixServerWeb.RobotChannel do
  use Phoenix.Channel

  @doc """
  Handler function for any Client joining the channel with topic "robot:status".
  Subscribe to the topic named "robot:update" on the Phoenix Server using Endpoint.
  Reply or Acknowledge with socket PID received from the Client.
  """
  def join("robot:status", _params, socket) do
    Task4CPhoenixServerWeb.Endpoint.subscribe("robot:update")
    Task4CPhoenixServerWeb.Endpoint.subscribe("timer:update")
    socket = assign(socket, :timer_tick, 180)
    {:ok, socket}
  end

  def join("robot:position", _params, socket) do
    Task4CPhoenixServerWeb.Endpoint.subscribe("robot:get_position")
    {:ok, socket}
  end

  def handle_info(%{event: "update_timer_tick", payload: timer_data, topic: "timer:update"}, socket) do
    socket = assign(socket, :timer_tick, timer_data.time)
    {:noreply, socket}
  end

  def handle_in("event_msg", message, socket) do
    message = Map.put(message, "timer", socket.assigns[:timer_tick])
    Task4CPhoenixServerWeb.Endpoint.broadcast_from(self(), "robot:status", "event_msg", message)
    {:reply, {:ok, true}, socket}
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
    data = message["value"]
    is_obs_ahead =
      Task4CPhoenixServerWeb.FindObstaclePresence.is_obstacle_ahead?(
        data["x"],
        data["y"],
        data["face"]
      )
    {:ok, out_file} = File.open("task_4c_output.txt", [:append])
    IO.binwrite(
      out_file,
      "#{data["client"]} => #{data["x"]}, #{data["y"]}, #{data["face"]}\n"
    )
    if message["client"] == "robot_A" do
      Task4CPhoenixServerWeb.Endpoint.broadcast("robot:get_position", "update_data", {:robot_a_curr_pos,data})
    else
      Task4CPhoenixServerWeb.Endpoint.broadcast("robot:get_position", "update_data", {:robot_b_curr_pos,data})
    end
    map_left_value_to_x = %{1 => 0, 2 => 150, 3 => 300, 4 => 450, 5 => 600, 6 => 750}
    map_bottom_value_to_y = %{
      "a" => 0,
      "b" => 150,
      "c" => 300,
      "d" => 450,
      "e" => 600,
      "f" => 750
    }
    left_value = Map.get(map_left_value_to_x, data["x"])
    bottom_value = Map.get(map_bottom_value_to_y, data["y"])
    dataa = %{
      "obs" => data["obstacle_prescence"],
      "client" => message["client"],
      "left" => left_value,
      "bottom" => bottom_value,
      "face" => data["face"]
    }
    Phoenix.PubSub.broadcast(Task4CPhoenixServer.PubSub, "robot:update", dataa)
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


  # def handle_in("obstacle_present", message, socket) do
  #   position = "ok"
  #   data = message["value"]
  #   {:reply, {:ok, position}, socket}
  # end
  def handle_in("give_roba_pos", _message, socket) do
    position =
    if socket.assigns.robot_a_stop and socket.assigns.robot_b_stop do
      Task4CPhoenixServerWeb.Endpoint.broadcast("timer:start", "stop_timer","nil")
      "timer stoped"
    else
      position = socket.assigns.robot_a_curr_pos
    end

    {:reply, {:ok, position}, socket}
  end
  def handle_in("give_robb_pos", _message, socket) do
    position =
    if socket.assigns.robot_a_stop and socket.assigns.robot_b_stop do
      Task4CPhoenixServerWeb.Endpoint.broadcast("timer:start", "stop_timer","nil")
      "timer stoped"
    else
      position = socket.assigns.robot_b_curr_pos
    end

    {:reply, {:ok, position}, socket}
  end

  def handle_in("stop_a", _message, socket) do
    position = "stoped"
    Task4CPhoenixServerWeb.Endpoint.broadcast("robot:get_position", "update_data", {:robot_a_stop,true})
    {:reply, {:ok, position}, socket}
  end
  def handle_in("stop_b", _message, socket) do
    position = "stoped"
    Task4CPhoenixServerWeb.Endpoint.broadcast("robot:get_position", "update_data", {:robot_b_stop,true})
    {:reply, {:ok, position}, socket}
  end

  def handle_in("update_dispenser_status", message, socket) do
    if message == "left" do
      left_dispenser_seeds = socket.assigns.left_disp_seeds - 1
      Task4CPhoenixServerWeb.Endpoint.broadcast("robot:get_position", "update_data", {:left_disp_seeds,left_dispenser_seeds})
    else
      right_dispenser_seeds = socket.assigns.right_disp_seeds - 1
      Task4CPhoenixServerWeb.Endpoint.broadcast("robot:get_position", "update_data", {:right_disp_seeds,right_dispenser_seeds})
    end
    {:reply, {:ok, "nil"}, socket}
  end

  def handle_in("give_dispenser_status", _message, socket) do
    status_left_disp = socket.assigns.left_disp_seeds
    status_right_disp = socket.assigns.right_disp_seeds
    status = %{"left" => status_left_disp, "right" => status_right_disp}
    {:reply, {:ok, status}, socket}
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

  def handle_in("give_goal_loc_a", _message, socket) do
    # wait_for_arena_live(message)
    # socket = assign(socket, :robota_start_pos,message)
    position =
      if Map.has_key?(socket.assigns, :roba_goal_locs) == false do
        position = "goal pos not recived"
      else
        position = socket.assigns.roba_goal_locs
      end

    {:reply, {:ok, position}, socket}
  end
  def handle_in("give_goal_loc_a_cell", _message, socket) do
    # wait_for_arena_live(message)
    # socket = assign(socket, :robota_start_pos,message)
    position =
      if Map.has_key?(socket.assigns, :roba_goal_locs) == false do
        position = "goal pos not recived"
      else
        position = socket.assigns.roba_goal_locs_cell
      end

    {:reply, {:ok, position}, socket}
  end
  def handle_in("give_goal_loc_b", _message, socket) do
    # wait_for_arena_live(message)
    # socket = assign(socket, :robota_start_pos,message)
    position =
      if Map.has_key?(socket.assigns, :robb_goal_locs) == false do
        position = "goal pos not recived"
      else
        position = socket.assigns.robb_goal_locs
      end

    {:reply, {:ok, position}, socket}
  end
  def handle_in("give_goal_loc_b_cell", _message, socket) do
    # wait_for_arena_live(message)
    # socket = assign(socket, :robota_start_pos,message)
    position =
      if Map.has_key?(socket.assigns, :robb_goal_locs) == false do
        position = "goal pos not recived"
      else
        position = socket.assigns.robb_goal_locs_cell
      end

    {:reply, {:ok, position}, socket}
  end

  # callback invoked when start positions are broadcasted from the areana live module
  def handle_info(%{event: "startPos", payload: data}, socket) do
    socket = assign(socket, :robota_start_pos, data["robotA_start"])
    socket = assign(socket, :robotb_start_pos, data["robotB_start"])
    socket = assign(socket, :roba_goal_locs, data["goal_locs_a"])
    socket = assign(socket, :roba_goal_locs_cell, data["goal_locs_a_cell"])
    socket = assign(socket, :robb_goal_locs, data["goal_locs_b"])
    socket = assign(socket, :robb_goal_locs_cell, data["goal_locs_b_cell"])
    socket = assign(socket, :goal_locs_unparsed, data["goal_locs_unparsed"])
    socket = assign(socket, :robot_a_stop, false)
    socket = assign(socket, :robot_b_stop, false)
    socket = assign(socket, :left_disp_seeds,3)
    socket = assign(socket, :right_disp_seeds,3)
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
    {:noreply, socket}
  end
  #########################################
  ## define callback functions as needed ##
  #########################################
end
