defmodule ToyRobot.PhoenixSocketClient do

  alias PhoenixClient.{Socket, _channel, Message}

  @doc """
  Connect to the Phoenix Server URL (defined in config.exs) via socket.
  Once ensured that socket is connected, join the _channel on the server with topic "robot:status".
  Get the _channel's PID in return after joining it.

  NOTE:
  The socket will automatically attempt to connect when it starts.
  If the socket becomes disconnected, it will attempt to reconnect automatically.
  Please note that start_link is not synchronous,
  so you must wait for the socket to become connected before attempting to join a _channel.
  Reference to above note: https://github.com/mobileoverlord/phoenix_client#usage

  You may refer: https://github.com/mobileoverlord/phoenix_client/issues/29#issuecomment-660518498
  """
  def connect_server do
    ###########################
    ## complete this funcion ##
    ###########################
    receive do
      {:obstacle_presence, is_obs_ahead} -> is_obs_ahead
    end
  end

  @doc """
  Send Toy Robot's current status i.e. location (x, y) and facing
  to the _channel's PID with topic "robot:status" on Phoenix Server with the event named "new_msg". The message to be sent should be a Map.
  In return from Phoenix server, receive the boolean value < true OR false > indicating the obstacle's presence
  in this format: {:ok, < true OR false >}.
  Create a tuple of this format: '{:obstacle_presence, < true or false >}' as a return of this function.
  """
  def send_robot_status(_channel, %ToyRobot.Position{x: x, y: y, facing: facing} = robot) do
    ###########################
    ## complete this funcion ##
    ###########################
    send(channel, {:toyrobot_status, x, y, facing})
    #IO.puts("Sent by Toy Robot Client: #{x}, #{y}, #{facing}")
    connect_server()
  end

end
