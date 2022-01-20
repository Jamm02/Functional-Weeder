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
    is_obs_ahead = Task4CPhoenixServerWeb.FindObstaclePresence.is_obstacle_ahead?(message["x"], message["y"], message["face"])
    {:ok, out_file} = File.open("task_4c_output.txt", [:append])
    IO.binwrite(out_file, "#{message["client"]} => #{message["x"]}, #{message["y"]}, #{message["face"]}\n")


    map_left_value_to_x = %{1 => 0, 2 => 150, 3 => 300, 4 => 450, 5 => 600, 6 => 750}
    map_bottom_value_to_y = %{"a" => 0, "b" => 150, "c" => 300, "d" => 450, "e" => 600, "f" => 750}
    left_value = Map.get(map_left_value_to_x,message["x"])
    bottom_value = Map.get(map_bottom_value_to_y, message["y"])
    data =
      if is_obs_ahead == false do
        data = %{ "client" => message["client"], "left" => left_value, "bottom" => bottom_value, "face" =>  message["face"] }
      else
        data = %{ "obs" => "true", "left" => left_value, "bottom" => bottom_value, "face" =>  message["face"] }
      end
    Phoenix.PubSub.broadcast(Task4CPhoenixServer.PubSub, "robot:update", data)
    # Task4CPhoenixServerWeb.Endpoint.broadcast("robot:update","", data)
    {:reply, {:ok, is_obs_ahead}, socket}
  end

  #callback invoked when message is pushed from the robot client.
  def handle_in("give_start_pos", message, socket) do
    # wait_for_arena_live(message)
    # socket = assign(socket, :robota_start_pos,message)
    position =
    if Map.has_key?(socket.assigns,:robota_start_pos) == false do
      position = "start pos not recived"
    else
      position = socket.assigns.robota_start_pos
    end
    IO.inspect(position)
    IO.inspect(socket)
    {:reply, {:ok, position}, socket}
  end

  #callback invoked when start positions are broadcasted from the areana live module
  def handle_info(%{event: "startPos", payload: data}, socket) do
    socket = assign(socket, :robota_start_pos, data["robotA_start"])
    #socket with the robot:postion
    IO.puts("callback to update called")
    {:noreply, socket}
  end
  def handle_info(msg, socket) do
    {:noreply, socket}
  end
  #########################################
  ## define callback functions as needed ##
  #########################################

end
