defmodule Task2PhoenixServerWeb.RobotChannel do
  use Phoenix.Channel

  @doc """
  Handler function for any Client joining the channel with topic "robot:status".
  Reply or Acknowledge with socket PID received from the Client.
  """
  def join("robot:status", _params, socket) do
    {:ok, socket}
  end

  @doc """
  Callback function for messages that are pushed to the channel with "robot:status" topic with an event named "new_msg".
  Receive the message from the Client, parse it to create another Map strictly of this format:
  %{ "left" => < left_value >, "bottom" => < bottom_value >, "face" => < face_value > }

  These values should be pixel locations for the robot's image to be displayed on the Dashboard
  corresponding to the various actions of the robot as recevied from the Client.

  Subscribe to the topic named "robot:update" on the Phoenix Server as PubSub and then
  broadcast the created Map of pixel locations, so that the ArenaLive module can update
  the robot's image and location on the Dashboard as soon as it receives the new data.

  Based on the message from the Client, determine the obstacle's presence in front of the robot
  and return the boolean value in this format {:ok, < true OR false >}.
  """
  def handle_in("new_msg", message, socket) do

    #Write your logic before the comment: "complete this function".

    cond do
      x == 1 -> left_value = 0
      x == 2 -> left_value = 150
      x == 3 -> left_value = 300
      x == 4 -> left_value = 450
      x == 5 -> left_value = 600

    end


    cond do
      y == "a" -> bottom_value = 0
      y == "b" -> bottom_value = 150
      y == "c" -> bottom_value = 300
      y == "d" -> bottom_value = 450
      y == "e" -> bottom_value = 600

    end

    map = %{ "left" => left_value, "bottom" => bottom_value >, "face" =>  face_value }

    :ok = Phoenix.PubSub.subscribe(Task2PhoenixServer.PubSub, "robot:update")
    Phoenix.PubSub.broadcast(Task2PhoenixServer.PubSub, @topic, {map})

    #map = robot
    #is_obs = PhoenixServer.Channel.push(channel, "new_msg", map)
    ###########################
    ## complete this funcion ##
    ###########################

    # determine the obstacle's presence in front of the robot and return the boolean value
    is_obs_ahead = Task2PhoenixServerWeb.FindObstaclePresence.is_obstacle_ahead?(message["x"], message["y"], message["face"])

    # file object to write each action taken by Toy Robot
    {:ok, out_file} = File.open("task_2_output.txt", [:append])
    # write the robot actions to a text file
    IO.binwrite(out_file, "#{message["x"]}, #{message["y"]}, #{message["face"]}\n")

    {:reply, {:ok, is_obs_ahead}, socket}
  end
end
