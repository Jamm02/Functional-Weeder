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

  if (message["x"] == 1) do
    left_value = 0
    if (message["y"] == "a") do
      bottom_value = 0
      face_value = message["face"]
      data = %{ "left" => left_value, "bottom" => bottom_value, "face" =>  face_value }
      Phoenix.PubSub.broadcast(Task2PhoenixServer.PubSub, "robot:update", data)

    else if (message["y"] == "b") do
      bottom_value = 150
      face_value = message["face"]
      data = %{ "left" => left_value, "bottom" => bottom_value, "face" =>  face_value }
      Phoenix.PubSub.broadcast(Task2PhoenixServer.PubSub, "robot:update", data)

    else if (message["y"] == "c") do
      bottom_value = 300
      face_value = message["face"]
      data = %{ "left" => left_value, "bottom" => bottom_value, "face" =>  face_value }
      Phoenix.PubSub.broadcast(Task2PhoenixServer.PubSub, "robot:update", data)

    else if (message["y"] == "d") do
      bottom_value = 450
      face_value = message["face"]
      data = %{ "left" => left_value, "bottom" => bottom_value, "face" =>  face_value }
      Phoenix.PubSub.broadcast(Task2PhoenixServer.PubSub, "robot:update", data)

    else if (message["y"] == "e") do
      bottom_value = 600
      face_value = message["face"]
      data = %{ "left" => left_value, "bottom" => bottom_value, "face" =>  face_value }
      Phoenix.PubSub.broadcast(Task2PhoenixServer.PubSub, "robot:update", data)
    end
    end
    end
    end
    end

  else if (message["x"] == 2) do
    left_value = 150
    if (message["y"] == "a") do
      bottom_value = 0
      face_value = message["face"]
      data = %{ "left" => left_value, "bottom" => bottom_value, "face" =>  face_value }
      Phoenix.PubSub.broadcast(Task2PhoenixServer.PubSub, "robot:update", data)

    else if (message["y"] == "b") do
      bottom_value = 150
      face_value = message["face"]
      data = %{ "left" => left_value, "bottom" => bottom_value, "face" =>  face_value }
      Phoenix.PubSub.broadcast(Task2PhoenixServer.PubSub, "robot:update", data)

    else if (message["y"] == "c") do
      bottom_value = 300
      face_value = message["face"]
      data = %{ "left" => left_value, "bottom" => bottom_value, "face" =>  face_value }
      Phoenix.PubSub.broadcast(Task2PhoenixServer.PubSub, "robot:update", data)

    else if (message["y"] == "d") do
      bottom_value = 450
      face_value = message["face"]
      data = %{ "left" => left_value, "bottom" => bottom_value, "face" =>  face_value }
      Phoenix.PubSub.broadcast(Task2PhoenixServer.PubSub, "robot:update", data)

    else if (message["y"] == "e") do
      bottom_value = 600
      face_value = message["face"]
      data = %{ "left" => left_value, "bottom" => bottom_value, "face" =>  face_value }
      Phoenix.PubSub.broadcast(Task2PhoenixServer.PubSub, "robot:update", data)
    end
    end
    end
    end
    end

  else if (message["x"] == 3) do
    left_value = 300
    if (message["y"] == "a") do
      bottom_value = 0
      face_value = message["face"]
      data = %{ "left" => left_value, "bottom" => bottom_value, "face" =>  face_value }
      Phoenix.PubSub.broadcast(Task2PhoenixServer.PubSub, "robot:update", data)

    else if (message["y"] == "b") do
      bottom_value = 150
      face_value = message["face"]
      data = %{ "left" => left_value, "bottom" => bottom_value, "face" =>  face_value }
      Phoenix.PubSub.broadcast(Task2PhoenixServer.PubSub, "robot:update", data)

    else if (message["y"] == "c") do
      bottom_value = 300
      face_value = message["face"]
      data = %{ "left" => left_value, "bottom" => bottom_value, "face" =>  face_value }
      Phoenix.PubSub.broadcast(Task2PhoenixServer.PubSub, "robot:update", data)

    else if (message["y"] == "d") do
      bottom_value = 450
      face_value = message["face"]
      data = %{ "left" => left_value, "bottom" => bottom_value, "face" =>  face_value }
      Phoenix.PubSub.broadcast(Task2PhoenixServer.PubSub, "robot:update", data)

    else if (message["y"] == "e") do
      bottom_value = 600
      face_value = message["face"]
      data = %{ "left" => left_value, "bottom" => bottom_value, "face" =>  face_value }
      Phoenix.PubSub.broadcast(Task2PhoenixServer.PubSub, "robot:update", data)
    end
    end
    end
    end
    end

    else if (message["x"] == 4) do
      left_value = 450
      if (message["y"] == "a") do
        bottom_value = 0
        face_value = message["face"]
        data = %{ "left" => left_value, "bottom" => bottom_value, "face" =>  face_value }
        Phoenix.PubSub.broadcast(Task2PhoenixServer.PubSub, "robot:update", data)

      else if (message["y"] == "b") do
        bottom_value = 150
        face_value = message["face"]
        data = %{ "left" => left_value, "bottom" => bottom_value, "face" =>  face_value }
        Phoenix.PubSub.broadcast(Task2PhoenixServer.PubSub, "robot:update", data)

      else if (message["y"] == "c") do
        bottom_value = 300
        face_value = message["face"]
        data = %{ "left" => left_value, "bottom" => bottom_value, "face" =>  face_value }
        Phoenix.PubSub.broadcast(Task2PhoenixServer.PubSub, "robot:update", data)

      else if (message["y"] == "d") do
        bottom_value = 450
        face_value = message["face"]
        data = %{ "left" => left_value, "bottom" => bottom_value, "face" =>  face_value }
        Phoenix.PubSub.broadcast(Task2PhoenixServer.PubSub, "robot:update", data)

      else if (message["y"] == "e") do
        bottom_value = 600
        face_value = message["face"]
        data = %{ "left" => left_value, "bottom" => bottom_value, "face" =>  face_value }
        Phoenix.PubSub.broadcast(Task2PhoenixServer.PubSub, "robot:update", data)
      end
      end
      end
      end
      end

    else if (message["x"] == 5) do
      left_value = 600
      if (message["y"] == "a") do
        bottom_value = 0
        face_value = message["face"]
        data = %{ "left" => left_value, "bottom" => bottom_value, "face" =>  face_value }
        Phoenix.PubSub.broadcast(Task2PhoenixServer.PubSub, "robot:update", data)

      else if (message["y"] == "b") do
        bottom_value = 150
        face_value = message["face"]
        data = %{ "left" => left_value, "bottom" => bottom_value, "face" =>  face_value }
        Phoenix.PubSub.broadcast(Task2PhoenixServer.PubSub, "robot:update", data)

      else if (message["y"] == "c") do
        bottom_value = 300
        face_value = message["face"]
        data = %{ "left" => left_value, "bottom" => bottom_value, "face" =>  face_value }
        Phoenix.PubSub.broadcast(Task2PhoenixServer.PubSub, "robot:update", data)

      else if (message["y"] == "d") do
        bottom_value = 450
        face_value = message["face"]
        data = %{ "left" => left_value, "bottom" => bottom_value, "face" =>  face_value }
        Phoenix.PubSub.broadcast(Task2PhoenixServer.PubSub, "robot:update", data)

      else if (message["y"] == "e") do
        bottom_value = 600
        face_value = message["face"]
        data = %{ "left" => left_value, "bottom" => bottom_value, "face" =>  face_value }
        Phoenix.PubSub.broadcast(Task2PhoenixServer.PubSub, "robot:update", data)
      end
      end
      end
      end
      end
      end
    end
    end
    end
    end

    # determine the obstacle's presence in front of the robot and return the boolean value
    is_obs_ahead = Task2PhoenixServerWeb.FindObstaclePresence.is_obstacle_ahead?(message["x"], message["y"], message["face"])
    # IO.inspect(is_obs_ahead)
    # file object to write each action taken by Toy Robot
    {:ok, out_file} = File.open("task_2_output.txt", [:append])
    # write the robot actions to a text file
    IO.binwrite(out_file, "#{message["x"]}, #{message["y"]}, #{message["face"]}\n")

    {:reply, {:ok, is_obs_ahead}, socket}
  end
end
