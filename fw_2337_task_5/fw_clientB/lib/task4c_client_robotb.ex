defmodule Task4CClientRobotB do
  # max x-coordinate of table top
  @table_top_x 6
  # max y-coordinate of table top
  @table_top_y :f
  # mapping of y-coordinates
  @robot_map_y_atom_to_num %{:a => 1, :b => 2, :c => 3, :d => 4, :e => 5, :f => 6}

  require Logger
  use Bitwise
  alias Circuits.GPIO



  @sensor_pins [cs: 5, clock: 25, address: 24, dataout: 23]
  @ir_pins [dr: 16, dl: 19]
  @motor_pins [lf: 12, lb: 13, rf: 20, rb: 21]
  @pwm_pins [enl: 6, enr: 26]
  @servo_a_pin 27
  @servo_b_pin 22

  @ref_atoms [:cs, :clock, :address, :dataout]
  @lf_sensor_data %{sensor0: 0, sensor1: 0, sensor2: 0, sensor3: 0, sensor4: 0, sensor5: 0}
  @lf_sensor_map %{0 => :sensor0, 1 => :sensor1, 2 => :sensor2, 3 => :sensor3, 4 => :sensor4, 5 => :sensor5}

  @forward [0, 1, 1, 0]
  @backward [0, 1, 0, 1]
  @left [0, 1, 1, 0]
  @right [1, 0, 0, 1]
  @stop [0, 0, 0, 0]

  @duty_cycles [120, 0]
  @duty_cycles_left [170, 0]
  @pwm_frequency 50

  @left_const 90
  @right_const 90

  @only_right [0, 0, 1, 0]
  @only_left [0, 1, 0, 0]
  @kp 10
  @kd 2
  @ki 0.01

  @caplow 75
  @caphigh 110

  defmodule Constants do
    defstruct bin: [], og: []
  end

  def follow_line do
    error = 0.0
    prev_error = 0.0
    difference = 0.0
    cumulative_error = 0.0
    correction = 0.0
    node_cnt = 0
    black_cnt = 0
    start_follow(error, prev_error, difference, cumulative_error, correction, node_cnt, black_cnt)
  end

  def start_follow(error, prev_error, difference, cumulative_error, correction, node_cnt, black_cnt) do

   readings =  get_sensor_readings()
   k = readings.og
   newk = readings.bin

  #  IO.inspect(k)
  #  IO.inspect(newk)


   error = calc_err(k, newk, error, prev_error)
   error = 10 * error
   difference = error - prev_error
   cumulative_error = cumulative_error + error

   cumulative_error =
   if cumulative_error > 30 do
    30
   else if cumulative_error < -30 do
   -30
   else
     cumulative_error
   end
   end


   correction = @kp * error + @kd * difference + @ki * cumulative_error
   prev_error = error

   # IO.puts("error: #{error}")
   # IO.puts("corr: #{correction}")
   left_duty_cycle = @left_const - correction
   left_duty_cycle =
   if left_duty_cycle < @caplow do
     @caplow
   else if left_duty_cycle > @caphigh do
     @caphigh
   else
     left_duty_cycle
   end
 end

   right_duty_cycle = @right_const + correction
   right_duty_cycle =
   if right_duty_cycle < @caplow do
     @caplow
   else if right_duty_cycle > @caphigh do
     @caphigh
   else
     right_duty_cycle
   end
 end

#  IO.inspect("#{newk}")
 black_cnt=
   if(Enum.member?(newk, 1) == false) do
     black_cnt = black_cnt + 1
     black_cnt
   else
     black_cnt = 0
     black_cnt
   end


   # IO.puts("blkcnt: #{black_cnt}")

 # end
 # IO.puts("node_cnt: #{node_cnt}")

 black_cnt =
   if (black_cnt > 10) do
     stop()
     black_cnt
   else if (newk == [1, 1, 1, 1, 1]) do
     stop()
     black_cnt
   else if (Enum.count(newk, &(&1 > 0)) >= 3) do
    IO.inspect(newk)
    IO.puts("node")
    black_cnt
    stop()
    Process.sleep(1000)
   else
     # IO.puts("left #{left_duty_cycle}")
     # IO.puts("right #{right_duty_cycle}")

     # if(node_cnt < 4) do
       move(left_duty_cycle, right_duty_cycle)
     # else
       # stop()
     # end
     black_cnt
     end
   end
 end
 if (Enum.count(newk, &(&1 > 0)) <= 2) do
  start_follow(error, prev_error, difference, cumulative_error, correction, node_cnt, black_cnt)
 end
  end


  def get_sensor_readings do
    # Logger.debug("Testing white line sensors connected ")
    sensor_ref = Enum.map(@sensor_pins, fn {atom, pin_no} -> configure_sensor({atom, pin_no}) end)
    sensor_ref = Enum.map(sensor_ref, fn{_atom, ref_id} -> ref_id end)
    sensor_ref = Enum.zip(@ref_atoms, sensor_ref)

    error = 0.0
    prev_error = 0.0
    difference = 0.0
    cumulative_error = 0.0
    correction = 0.0
    node_cnt = 0
    black_cnt = 0
    get_lfa_readings([0,1,2,3,4], sensor_ref, error, prev_error, difference, cumulative_error, correction, node_cnt, black_cnt)
  end

  defp configure_sensor({atom, pin_no}) do
    if (atom == :dataout) do
      GPIO.open(pin_no, :input, pull_mode: :pullup)
    else
      GPIO.open(pin_no, :output)
    end
  end

  defp motor_new(motor_ref,motion) do
    motor_ref |> Enum.zip(motion) |> Enum.each(fn {{_, ref_no}, value} -> GPIO.write(ref_no, value) end)
    # Process.sleep(1000)
  end
  defp motor_action(motor_ref,motion) do
    motor_ref |> Enum.zip(motion) |> Enum.each(fn {{_, ref_no}, value} -> GPIO.write(ref_no, value) end)
  end


  def stop() do
    # Process.sleep(10)
    motor_ref = Enum.map(@motor_pins, fn {_atom, pin_no} -> GPIO.open(pin_no, :output) end)
    pwm_ref = Enum.map(@pwm_pins, fn {_atom, pin_no} -> GPIO.open(pin_no, :output) end)
    Enum.map(pwm_ref,fn {_, ref_no} -> GPIO.write(ref_no, 1) end)
    motion_list = [@stop]
    Enum.each(motion_list, fn motion -> motor_new(motor_ref,motion) end)
    # Process.sleep(1000)
  end


  defp move(l, r) do
    # IO.puts("l: #{l}")
    # IO.puts("r: #{r}")
    l = round(l)
    r = round(r)
    enr = 26
    enl = 6
    # Logger.debug("Testing Motion of the Robot ")
    motor_ref = Enum.map(@motor_pins, fn {_atom, pin_no} -> GPIO.open(pin_no, :output) end)
    motor_action(motor_ref, @forward)

      Pigpiox.Pwm.gpio_pwm(enl, l)
      Pigpiox.Pwm.gpio_pwm(enr, r)
  end

  defp get_lfa_readings(sensor_list, sensor_ref, error, prev_error, difference, cumulative_error, correction, node_cnt, black_cnt) do
    append_sensor_list = sensor_list ++ [5]
    temp_sensor_list = [5 | append_sensor_list]
    k = append_sensor_list
        |> Enum.with_index
        |> Enum.map(fn {sens_num, sens_idx} ->
              analog_read(sens_num, sensor_ref, Enum.fetch(temp_sensor_list, sens_idx))
              end)
    Enum.each(0..5, fn n -> provide_clock(sensor_ref) end)
    GPIO.write(sensor_ref[:cs], 1)
    Process.sleep(1)



    newk = new_read(k, 1, [])

    # IO.inspect(newk)
    k = List.delete_at(k, 0)
    temp = %Constants{bin: newk, og: k}

    Enum.each(0..5, fn n -> provide_clock(sensor_ref) end)
    GPIO.write(sensor_ref[:cs], 1)
    Process.sleep(1)
    temp
  end

  defp calc_err(k, newk, error, prev_error) do
    all_black_flag = 1
    weighted_sum = 0.0
    sum = 0
    pos = 0
    all_black_flag =
    if Enum.member?(newk, 1) == true do
      0
    else
      1
    end
    weighted_sum = (-3.0) * (Enum.at(k, 0)) + (-1.0) * (Enum.at(k, 1)) + (0) * (Enum.at(k, 2)) + (1.0) * (Enum.at(k, 3)) + (3.0) * (Enum.at(k, 4))
    # IO.puts("wsum #{weighted_sum}")
    error
    sum = Enum.at(k, 0) + Enum.at(k, 1) + Enum.at(k, 2) + Enum.at(k, 3) + Enum.at(k, 4)

   pos =
    if sum != 0 do
      weighted_sum / sum
    else
      0
    end

  error =
    if all_black_flag == 1 do
       if prev_error > 0 do
          error = 2.5
       else
          error = -2.5
       end
    else
      error = pos
    end
    # IO.puts("errornew #{error}")
    error
  end


  defp new_read(k, counter, new_list) do
    if (counter == 0) do
      counter = counter + 1
      new_read(k, counter, new_list)
    end

    if(counter < 6) do
      if(Enum.at(k, counter) > 940) do
        new_list = new_list ++ [1]
        counter = counter + 1
        new_read(k, counter, new_list)
      else
        new_list = new_list ++ [0]
        counter = counter + 1
        new_read(k, counter, new_list)
      end

    else
      # IO.puts("newk")
      # IO.inspect(new_list)
      new_list
    end

  end


  @doc """
  Supporting function for test_wlf_sensors
  """
  defp analog_read(sens_num, sensor_ref, {_, sensor_atom_num}) do

    GPIO.write(sensor_ref[:cs], 0)
    %{^sensor_atom_num => sensor_atom} = @lf_sensor_map
    Enum.reduce(0..9, @lf_sensor_data, fn n, acc ->
                                          read_data(n, acc, sens_num, sensor_ref, sensor_atom_num)
                                          |> clock_signal(n, sensor_ref)
                                        end)[sensor_atom]
  end

  @doc """
  Supporting function for test_wlf_sensors
  """
  defp read_data(n, acc, sens_num, sensor_ref, sensor_atom_num) do
    if (n < 4) do

      if (((sens_num) >>> (3 - n)) &&& 0x01) == 1 do
        GPIO.write(sensor_ref[:address], 1)
      else
        GPIO.write(sensor_ref[:address], 0)
      end
      Process.sleep(1)
    end

    %{^sensor_atom_num => sensor_atom} = @lf_sensor_map
    if (n <= 9) do
      Map.update!(acc, sensor_atom, fn sensor_atom -> ( sensor_atom <<< 1 ||| GPIO.read(sensor_ref[:dataout]) ) end)
    end
  end

  @doc """
  Supporting function for test_wlf_sensors used for providing clock pulses
  """
  defp provide_clock(sensor_ref) do
    GPIO.write(sensor_ref[:clock], 1)
    GPIO.write(sensor_ref[:clock], 0)
  end

  @doc """
  Supporting function for test_wlf_sensors used for providing clock pulses
  """
  defp clock_signal(acc, n, sensor_ref) do
    GPIO.write(sensor_ref[:clock], 1)
    GPIO.write(sensor_ref[:clock], 0)
    acc
  end


  defp motion_pwm(value) do
    # IO.puts("Forward with pwm value = #{value}")
    pwm(value)
    Process.sleep(620)
  end

  defp motion_pwm_left(value) do
    # IO.puts("Forward with pwm value = #{value}")
    pwm(value)
    Process.sleep(750)
  end


  defp pwm(duty) do
    Enum.each(@pwm_pins, fn {_atom, pin_no} -> Pigpiox.Pwm.gpio_pwm(pin_no, duty) end)
  end

  def check_for_obs(robot) do

    IO.inspect(robot)
    ir_ref = Enum.map(@ir_pins, fn {_atom, pin_no} -> GPIO.open(pin_no, :input, pull_mode: :pullup) end)
    ir_values = Enum.map(ir_ref,fn {_, ref_no} -> GPIO.read(ref_no) end)
    bool =
    if(ir_values == [1, 1]) do
      false
    else
      true
    end

  end



  @doc """
  Places the robot to the default position of (1, A, North)

  Examples:

      iex> Task4CClientRobotB.place
      {:ok, %Task4CClientRobotB.Position{facing: :north, x: 1, y: :a}}
  """
  def place do
    {:ok, %Task4CClientRobotB.Position{}}
  end

  def place(x, y, _facing) when x < 1 or y < :a or x > @table_top_x or y > @table_top_y do
    {:failure, "Invalid position"}
  end

  def place(_x, _y, facing) when facing not in [:north, :east, :south, :west] do
    {:failure, "Invalid facing direction"}
  end

  @doc """
  Places the robot to the provided position of (x, y, facing),
  but prevents it to be placed outside of the table and facing invalid direction.

  Examples:

      iex> Task4CClientRobotB.place(1, :b, :south)
      {:ok, %Task4CClientRobotB.Position{facing: :south, x: 1, y: :b}}

      iex> Task4CClientRobotB.place(-1, :f, :north)
      {:failure, "Invalid position"}

      iex> Task4CClientRobotB.place(3, :c, :north_east)
      {:failure, "Invalid facing direction"}
  """
  def place(x, y, facing) do
    {:ok, %Task4CClientRobotB.Position{x: x, y: y, facing: facing}}
  end

  @doc """
  Provide START position to the robot as given location of (x, y, facing) and place it.
  """
  def start(x, y, facing) do
    place(x, y, facing)
  end

  @doc """
  Main function to initiate the sequence of tasks to achieve by the Client Robot B,
  such as connect to the Phoenix server, get the robot B's start and goal locations to be traversed.
  Call the respective functions from this module and others as needed.
  You may create extra helper functions as needed.
  """
  def main do
    {:ok, _response, channel_status, channel_startPos} =
      Task4CClientRobotB.PhoenixSocketClient.connect_server()

    {:ok, position} = get_start_pos(channel_startPos)
    new = String.replace(position, " ", "")
    str = String.split(new, ",")
    {x, ""} = Integer.parse(Enum.at(str, 0))
    y = String.to_atom(Enum.at(str, 1))
    facing = String.to_atom(Enum.at(str, 2))
    start(x, y, facing)
    robot_start = %Task4CClientRobotB.Position{x: x, y: y, facing: facing}
    {:ok, goal_locs} = get_goal_locs(channel_startPos)
    {:ok, goal_locs_cell} = get_goal_locs_cell(channel_startPos)
    list_ret = []
    goalssssss = make_goal_list_for_cells(goal_locs_cell,list_ret)
    # IO.inspect(goalssssss)
    # IO.inspect(goal_locs_cell)
    # IO.inspect(goal_locs)
    # IO.inspect(robot_start)
    # goal_locs = Enum.reverse(goal_locs)
    # goalssssss = Enum.reverse(goalssssss)
    goal_locs = stop(robot_start, goal_locs, channel_status, channel_startPos,goalssssss)
    Process.sleep(5000)
    broadcast_stop(channel_startPos)
    rob = get_correct_robot_position(channel_startPos)
  end
  def make_goal_list_for_cells(goal_locs_cell,list_ret) do
    if Enum.empty?(goal_locs_cell) == true do
      list_ret
    else
      n = Enum.at(goal_locs_cell,0)
      list = get_goal(n)
      list_ret = list_ret ++ [list]
      goal_locs_cell = List.delete_at(goal_locs_cell,0)
      make_goal_list_for_cells(goal_locs_cell,list_ret)
    end
  end
  def get_goal(n) do
    map = %{1 => "a", 2 => "b", 3 => "c", 4 => "d", 5 => "e", 6 => "f"}
    n = String.to_integer(n)
    list =
      cond do
        n >= 1 and n <= 5 ->
          x1 = to_string(n)
          x2 =to_string(n+1)
          y1 = map[1]
          y2 = map[2]
          lst = [[x1,y1],[x1,y2],[x2,y1],[x2,y2]]
          # lst = [x1, y1]

        n >= 6 and n <= 10 ->
          x1 = to_string(n - 5)
          x2 =to_string(n-5+1)
          y1 = map[2]
          y2 = map[3]
          # lst = [x1,y1,x1,y2,x2,y1,x2,y2]
          lst = [[x1,y1],[x1,y2],[x2,y1],[x2,y2]]
          # lst = [x1, y1]

        n >= 11 and n <= 15 ->
          x1 = to_string(n - 10)
          x2 =to_string(n-10+1)
          y1 = map[3]
          y2 = map[4]
          # lst = [x1,y1,x1,y2,x2,y1,x2,y2]
          lst = [[x1,y1],[x1,y2],[x2,y1],[x2,y2]]
          # lst = [x1, y1]

        n >= 16 and n <= 20 ->
          x1 = to_string(n - 15)
          x2 =to_string(n-15+1)
          y1 = map[4]
          y2 = map[5]
          # lst = [x1, y1]
          lst = [[x1,y1],[x1,y2],[x2,y1],[x2,y2]]
        # lst = [x1,y1,x1,y2,x2,y1,x2,y2]
        n >= 21 and n <= 25 ->
          x1 = to_string(n - 20)
          x2 =to_string(n-20+1)
          y1 = map[5]
          y2 = map[6]
          # lst = [x1,y1,x1,y2,x2,y1,x2,y2]
          # lst = [x1, y1]
          lst = [[x1,y1],[x1,y2],[x2,y1],[x2,y2]]
      end
    list
  end

  def broadcast_stop(channel_position) do
    {:ok, reply} = PhoenixClient.Channel.push(channel_position, "stop_b", "nil")
  end

  # fucntio to get the start positions entered by the user on the server arena live
  def get_start_pos(channel) do
    {:ok, position} = PhoenixClient.Channel.push(channel, "give_start_posb", "nil")

    position =
      if position == "start pos not recived" do
        # Process.sleep(3000)
        {:ok, position} = get_start_pos(channel)
        position
      else
        position
      end

    {:ok, position}
  end

  # fucntion to get the goal location from the csv file in the server
  def get_goal_locs(channel) do
    {:ok, goal_locs} = PhoenixClient.Channel.push(channel, "give_goal_loc_b", "nil")

    goal_locs =
      if goal_locs == "goal pos not recived" do
        # Process.sleep(3000)
        {:ok, goal_locs} = get_goal_locs(channel)
        goal_locs
      else
        goal_locs
      end

    {:ok, goal_locs}
  end

  def get_goal_locs_cell(channel) do
    {:ok, goal_locs} = PhoenixClient.Channel.push(channel, "give_goal_loc_b_cell", "nil")

    goal_locs =
      if goal_locs == "goal pos not recived" do
        # Process.sleep(3000)
        {:ok, goal_locs} = get_goal_locs(channel)
        goal_locs
      else
        goal_locs
      end

    {:ok, goal_locs}
  end

  def correct_X(
        %Task4CClientRobotB.Position{x: x, y: y, facing: facing} = robot,
        goal_x,
        goal_y,
        channel_status,
        channel_position,
        goal_list
      ) do
    %Task4CClientRobotB.Position{x: x, y: y, facing: facing} = robot

    if(goal_x == x) do
      # is_obs = Task4CClientRobotB.PhoenixSocketClient.send_robot_status(channel_status, channel_position,robot)
      go_to_goal(robot, goal_x, goal_y, channel_status, channel_position, goal_list)
      {:ok, robot}
    else
      is_obs =
        Task4CClientRobotB.PhoenixSocketClient.send_robot_status(
          channel_status,
          channel_position,
          robot
        )

      if x > goal_x do
        if facing != :west do
          robot = right(robot)
          %Task4CClientRobotB.Position{x: x, y: y, facing: facing} = robot
          # send_robot_status(robot, channel_status, channel_position)
          # is_obs = check_for_obs(robot,channel_status, channel_position)
          correct_X(robot, goal_x, goal_y, channel_status, channel_position, goal_list)
        else
          %Task4CClientRobotB.Position{x: x, y: y, facing: facing} = robot
          # is_obs = check_for_obs(robot,channel_status, channel_position)

          if(is_obs) do
            # IO.puts("Obstacle at #{x}, #{y}, #{facing}")
            objInX_west(
              robot,
              goal_x,
              goal_y,
              channel_status,
              channel_position,
              repeat = 0,
              goal_list
            )

            %Task4CClientRobotB.Position{x: x, y: y, facing: facing} = robot
          else
            robot = move(robot)
            %Task4CClientRobotB.Position{x: x, y: y, facing: facing} = robot
            correct_X(robot, goal_x, goal_y, channel_status, channel_position, goal_list)
          end
        end

        # send_robot_status(robot, channel_status, channel_position)
      else
        if x < goal_x do
          # is_obs = Task4CClientRobotB.PhoenixSocketClient.send_robot_status(channel_status, channel_position,robot)
          %Task4CClientRobotB.Position{x: x, y: y, facing: facing} = robot

          if facing != :east do
            robot = right(robot)
            %Task4CClientRobotB.Position{x: x, y: y, facing: facing} = robot
            # send_robot_status(robot, channel_status, channel_position)
            # is_obs = check_for_obs(robot,channel_status, channel_position)
            correct_X(robot, goal_x, goal_y, channel_status, channel_position, goal_list)
          else
            %Task4CClientRobotB.Position{x: x, y: y, facing: facing} = robot
            # is_obs = check_for_obs(robot,channel_status, channel_position)

            if(is_obs) do
              # IO.put("Obstacle at #{x + 1}, #{y}")
              # IO.puts("Obstacle at #{x}, #{y}, #{facing}")
              objInX_east(robot, goal_x, goal_y, channel_status, channel_position, repeat = 0,goal_list)
              %Task4CClientRobotB.Position{x: x, y: y, facing: facing} = robot
            else
              robot = move(robot)
              %Task4CClientRobotB.Position{x: x, y: y, facing: facing} = robot
              correct_X(robot, goal_x, goal_y, channel_status, channel_position, goal_list)
            end
          end
        end
      end
    end
  end

  def objInY_north(
        %Task4CClientRobotB.Position{x: x, y: y, facing: facing} = robot,
        goal_x,
        goal_y,
        channel_status,
        channel_position,
        repeat,
        goal_list
      ) do
    %Task4CClientRobotB.Position{x: x, y: y, facing: facing} = robot

    # make sure bot is facing north
    # IO.puts("in north")
    # turn and right and face north
    # turn and move left and face north
    if x == 1 or repeat == 1 do
      # IO.puts("in 1")
      robot = right(robot)
      %Task4CClientRobotB.Position{x: x, y: y, facing: facing} = robot

      is_obs =
        Task4CClientRobotB.PhoenixSocketClient.send_robot_status(
          channel_status,
          channel_position,
          robot
        )

      if(is_obs) do
        robot = right(robot)
        %Task4CClientRobotB.Position{x: x, y: y, facing: facing} = robot

        is_obs =
          Task4CClientRobotB.PhoenixSocketClient.send_robot_status(
            channel_status,
            channel_position,
            robot
          )

        robot = move(robot)
        %Task4CClientRobotB.Position{x: x, y: y, facing: facing} = robot

        is_obs =
          Task4CClientRobotB.PhoenixSocketClient.send_robot_status(
            channel_status,
            channel_position,
            robot
          )

        robot = left(robot)
        %Task4CClientRobotB.Position{x: x, y: y, facing: facing} = robot

        is_obs =
          Task4CClientRobotB.PhoenixSocketClient.send_robot_status(
            channel_status,
            channel_position,
            robot
          )

        if(is_obs) do
          objInX_east(
            %Task4CClientRobotB.Position{x: x, y: y, facing: facing} = robot,
            goal_x,
            goal_y,
            channel_status,
            channel_position,
            repeat = 0,
            goal_list
          )
        else
          robot = move(robot)
          %Task4CClientRobotB.Position{x: x, y: y, facing: facing} = robot

          # is_obs = Task4CClientRobotB.PhoenixSocketClient.send_robot_status(channel_status, channel_position,robot)
          go_to_goal(robot, goal_x, goal_y, channel_status, channel_position, goal_list)
        end

        %Task4CClientRobotB.Position{x: x, y: y, facing: facing} = robot
      else
        robot = move(robot)
        %Task4CClientRobotB.Position{x: x, y: y, facing: facing} = robot

        is_obs =
          Task4CClientRobotB.PhoenixSocketClient.send_robot_status(
            channel_status,
            channel_position,
            robot
          )

        robot = left(robot)

        is_obs =
          Task4CClientRobotB.PhoenixSocketClient.send_robot_status(
            channel_status,
            channel_position,
            robot
          )

        %Task4CClientRobotB.Position{x: x, y: y, facing: facing} = robot

        if is_obs do
          repeat = 1
          objInY_north(robot, goal_x, goal_y, channel_status, channel_position, repeat, goal_list)
        else
          robot = move(robot)
          %Task4CClientRobotB.Position{x: x, y: y, facing: facing} = robot

          # is_obs = Task4CClientRobotB.PhoenixSocketClient.send_robot_status(channel_status, channel_position,robot)
          if x != goal_x do
            correct_X(robot, goal_x, goal_y, channel_status, channel_position, goal_list)
          else
            go_to_goal(robot, goal_x, goal_y, channel_status, channel_position, goal_list)
          end
        end

        %Task4CClientRobotB.Position{x: x, y: y, facing: facing} = robot

        # IO.puts("exited if")
      end
    else
      # IO.puts("in 2")
      robot = left(robot)
      %Task4CClientRobotB.Position{x: x, y: y, facing: facing} = robot

      is_obs =
        Task4CClientRobotB.PhoenixSocketClient.send_robot_status(
          channel_status,
          channel_position,
          robot
        )

      if(is_obs) do
        robot = left(robot)
        %Task4CClientRobotB.Position{x: x, y: y, facing: facing} = robot

        is_obs =
          Task4CClientRobotB.PhoenixSocketClient.send_robot_status(
            channel_status,
            channel_position,
            robot
          )

        robot = move(robot)
        %Task4CClientRobotB.Position{x: x, y: y, facing: facing} = robot

        is_obs =
          Task4CClientRobotB.PhoenixSocketClient.send_robot_status(
            channel_status,
            channel_position,
            robot
          )

        robot = right(robot)
        %Task4CClientRobotB.Position{x: x, y: y, facing: facing} = robot

        is_obs =
          Task4CClientRobotB.PhoenixSocketClient.send_robot_status(
            channel_status,
            channel_position,
            robot
          )

        if(is_obs) do
          objInX_west(
            %Task4CClientRobotB.Position{x: x, y: y, facing: facing} = robot,
            goal_x,
            goal_y,
            channel_status,
            channel_position,
            repeat = 0,
            goal_list
          )
        else
          robot = move(robot)
          %Task4CClientRobotB.Position{x: x, y: y, facing: facing} = robot

          # is_obs = Task4CClientRobotB.PhoenixSocketClient.send_robot_status(channel_status, channel_position,robot)
          go_to_goal(robot, goal_x, goal_y, channel_status, channel_position, goal_list)
        end

        %Task4CClientRobotB.Position{x: x, y: y, facing: facing} = robot
      else
        robot = move(robot)
        %Task4CClientRobotB.Position{x: x, y: y, facing: facing} = robot

        is_obs =
          Task4CClientRobotB.PhoenixSocketClient.send_robot_status(
            channel_status,
            channel_position,
            robot
          )

        robot = right(robot)
        %Task4CClientRobotB.Position{x: x, y: y, facing: facing} = robot

        is_obs =
          Task4CClientRobotB.PhoenixSocketClient.send_robot_status(
            channel_status,
            channel_position,
            robot
          )

        if is_obs do
          repeat = 0
          objInY_north(robot, goal_x, goal_y, channel_status, channel_position, repeat, goal_list)
        else
          robot = move(robot)

          # is_obs = Task4CClientRobotB.PhoenixSocketClient.send_robot_status(channel_status, channel_position,robot)
          %Task4CClientRobotB.Position{x: x, y: y, facing: facing} = robot

          if x != goal_x do
            correct_X(robot, goal_x, goal_y, channel_status, channel_position, goal_list)
          else
            go_to_goal(robot, goal_x, goal_y, channel_status, channel_position, goal_list)
          end
        end

        %Task4CClientRobotB.Position{x: x, y: y, facing: facing} = robot
        # IO.puts("exited else")
      end
    end

    %Task4CClientRobotB.Position{x: x, y: y, facing: facing} = robot
    # IO.puts("#{x}, #{y}, #{facing}")
    # call the base go_to_goal func at this point
  end

  def objInY_south(
        %Task4CClientRobotB.Position{x: x, y: y, facing: facing} = robot,
        goal_x,
        goal_y,
        channel_status,
        channel_position,
        repeat,
        goal_list
      ) do
    # make sure bot is facing south
    # IO.puts("in south")

    %Task4CClientRobotB.Position{x: x, y: y, facing: facing} = robot
    # turn, move left and face south
    # turn, move right and go south
    if x == 1 or repeat == 1 do
      robot = left(robot)
      %Task4CClientRobotB.Position{x: x, y: y, facing: facing} = robot

      is_obs =
        Task4CClientRobotB.PhoenixSocketClient.send_robot_status(
          channel_status,
          channel_position,
          robot
        )

      if(is_obs) do
        robot = left(robot)
        %Task4CClientRobotB.Position{x: x, y: y, facing: facing} = robot

        is_obs =
          Task4CClientRobotB.PhoenixSocketClient.send_robot_status(
            channel_status,
            channel_position,
            robot
          )

        robot = move(robot)
        %Task4CClientRobotB.Position{x: x, y: y, facing: facing} = robot

        is_obs =
          Task4CClientRobotB.PhoenixSocketClient.send_robot_status(
            channel_status,
            channel_position,
            robot
          )

        robot = right(robot)
        %Task4CClientRobotB.Position{x: x, y: y, facing: facing} = robot

        is_obs =
          Task4CClientRobotB.PhoenixSocketClient.send_robot_status(
            channel_status,
            channel_position,
            robot
          )

        if(is_obs) do
          objInX_east(
            %Task4CClientRobotB.Position{x: x, y: y, facing: facing} = robot,
            goal_x,
            goal_y,
            channel_status,
            channel_position,
            repeat = 0,
            goal_list
          )
        else
          robot = move(robot)
          %Task4CClientRobotB.Position{x: x, y: y, facing: facing} = robot

          # is_obs = Task4CClientRobotB.PhoenixSocketClient.send_robot_status(channel_status, channel_position,robot)
          go_to_goal(robot, goal_x, goal_y, channel_status, channel_position, goal_list)
        end

        %Task4CClientRobotB.Position{x: x, y: y, facing: facing} = robot
      else
        robot = move(robot)
        %Task4CClientRobotB.Position{x: x, y: y, facing: facing} = robot

        is_obs =
          Task4CClientRobotB.PhoenixSocketClient.send_robot_status(
            channel_status,
            channel_position,
            robot
          )

        robot = right(robot)
        %Task4CClientRobotB.Position{x: x, y: y, facing: facing} = robot

        is_obs =
          Task4CClientRobotB.PhoenixSocketClient.send_robot_status(
            channel_status,
            channel_position,
            robot
          )

        if is_obs do
          repeat = 1
          objInY_south(robot, goal_x, goal_y, channel_status, channel_position, repeat, goal_list)
        else
          robot = move(robot)
          %Task4CClientRobotB.Position{x: x, y: y, facing: facing} = robot

          # is_obs = Task4CClientRobotB.PhoenixSocketClient.send_robot_status(channel_status, channel_position,robot)
          if x != goal_x do
            correct_X(robot, goal_x, goal_y, channel_status, channel_position, goal_list)
          else
            go_to_goal(robot, goal_x, goal_y, channel_status, channel_position, goal_list)
          end
        end

        %Task4CClientRobotB.Position{x: x, y: y, facing: facing} = robot
        # IO.puts("exited else")
      end
    else
      robot = right(robot)
      %Task4CClientRobotB.Position{x: x, y: y, facing: facing} = robot

      is_obs =
        Task4CClientRobotB.PhoenixSocketClient.send_robot_status(
          channel_status,
          channel_position,
          robot
        )

      if(is_obs) do
        robot = right(robot)
        %Task4CClientRobotB.Position{x: x, y: y, facing: facing} = robot

        is_obs =
          Task4CClientRobotB.PhoenixSocketClient.send_robot_status(
            channel_status,
            channel_position,
            robot
          )

        robot = move(robot)
        %Task4CClientRobotB.Position{x: x, y: y, facing: facing} = robot

        is_obs =
          Task4CClientRobotB.PhoenixSocketClient.send_robot_status(
            channel_status,
            channel_position,
            robot
          )

        robot = left(robot)
        %Task4CClientRobotB.Position{x: x, y: y, facing: facing} = robot

        is_obs =
          Task4CClientRobotB.PhoenixSocketClient.send_robot_status(
            channel_status,
            channel_position,
            robot
          )

        if(is_obs) do
          objInX_west(
            %Task4CClientRobotB.Position{x: x, y: y, facing: facing} = robot,
            goal_x,
            goal_y,
            channel_status,
            channel_position,
            repeat = 0,
            goal_list
          )
        else
          robot = move(robot)
          %Task4CClientRobotB.Position{x: x, y: y, facing: facing} = robot

          # is_obs = Task4CClientRobotB.PhoenixSocketClient.send_robot_status(channel_status, channel_position,robot)
          go_to_goal(robot, goal_x, goal_y, channel_status, channel_position, goal_list)
        end

        %Task4CClientRobotB.Position{x: x, y: y, facing: facing} = robot
      else
        robot = move(robot)
        %Task4CClientRobotB.Position{x: x, y: y, facing: facing} = robot

        is_obs =
          Task4CClientRobotB.PhoenixSocketClient.send_robot_status(
            channel_status,
            channel_position,
            robot
          )

        robot = left(robot)

        is_obs =
          Task4CClientRobotB.PhoenixSocketClient.send_robot_status(
            channel_status,
            channel_position,
            robot
          )

        %Task4CClientRobotB.Position{x: x, y: y, facing: facing} = robot

        if is_obs do
          repeat = 0
          objInY_south(robot, goal_x, goal_y, channel_status, channel_position, repeat, goal_list)
        else
          robot = move(robot)
          %Task4CClientRobotB.Position{x: x, y: y, facing: facing} = robot

          # is_obs = Task4CClientRobotB.PhoenixSocketClient.send_robot_status(channel_status, channel_position,robot)
          if x != goal_x do
            correct_X(robot, goal_x, goal_y, channel_status, channel_position, goal_list)
          else
            go_to_goal(robot, goal_x, goal_y, channel_status, channel_position, goal_list)
          end
        end

        %Task4CClientRobotB.Position{x: x, y: y, facing: facing} = robot
        # IO.puts("exited if")
      end
    end

    %Task4CClientRobotB.Position{x: x, y: y, facing: facing} = robot
    # call the base go_to_goal func at this point
    # go_to_goal(robot, goal_x, goal_y, channel_status, channel_position,goal_list)
  end

  def objInX_west(
        %Task4CClientRobotB.Position{x: x, y: y, facing: facing} = robot,
        goal_x,
        goal_y,
        channel_status,
        channel_position,
        repeat,
        goal_list
      ) do
    # make sure bot is facing west before running this func
    # IO.puts("in west")

    %Task4CClientRobotB.Position{x: x, y: y, facing: facing} = robot

    # turn, move left and face east
    # turn, move right and go south
    if y == :a or repeat == 1 do
      robot = right(robot)
      %Task4CClientRobotB.Position{x: x, y: y, facing: facing} = robot

      is_obs =
        Task4CClientRobotB.PhoenixSocketClient.send_robot_status(
          channel_status,
          channel_position,
          robot
        )

      if(is_obs) do
        robot = right(robot)
        %Task4CClientRobotB.Position{x: x, y: y, facing: facing} = robot

        is_obs =
          Task4CClientRobotB.PhoenixSocketClient.send_robot_status(
            channel_status,
            channel_position,
            robot
          )

        robot = move(robot)
        %Task4CClientRobotB.Position{x: x, y: y, facing: facing} = robot

        is_obs =
          Task4CClientRobotB.PhoenixSocketClient.send_robot_status(
            channel_status,
            channel_position,
            robot
          )

        robot = left(robot)
        %Task4CClientRobotB.Position{x: x, y: y, facing: facing} = robot

        is_obs =
          Task4CClientRobotB.PhoenixSocketClient.send_robot_status(
            channel_status,
            channel_position,
            robot
          )

        if(is_obs) do
          objInY_north(
            %Task4CClientRobotB.Position{x: x, y: y, facing: facing} = robot,
            goal_x,
            goal_y,
            channel_status,
            channel_position,
            repeat = 0,
            goal_list
          )
        else
          robot = move(robot)
          %Task4CClientRobotB.Position{x: x, y: y, facing: facing} = robot

          # is_obs = Task4CClientRobotB.PhoenixSocketClient.send_robot_status(channel_status, channel_position,robot)
          correct_X(robot, goal_x, goal_y, channel_status, channel_position, goal_list)
        end

        %Task4CClientRobotB.Position{x: x, y: y, facing: facing} = robot
      else
        robot = move(robot)
        %Task4CClientRobotB.Position{x: x, y: y, facing: facing} = robot

        is_obs =
          Task4CClientRobotB.PhoenixSocketClient.send_robot_status(
            channel_status,
            channel_position,
            robot
          )

        robot = left(robot)

        is_obs =
          Task4CClientRobotB.PhoenixSocketClient.send_robot_status(
            channel_status,
            channel_position,
            robot
          )

        %Task4CClientRobotB.Position{x: x, y: y, facing: facing} = robot

        if is_obs do
          repeat = 1
          objInX_west(robot, goal_x, goal_y, channel_status, channel_position, repeat, goal_list)
        else
          robot = move(robot)

          # is_obs = Task4CClientRobotB.PhoenixSocketClient.send_robot_status(channel_status, channel_position,robot)
          %Task4CClientRobotB.Position{x: x, y: y, facing: facing} = robot
          go_to_goal(robot, goal_x, goal_y, channel_status, channel_position, goal_list)
        end

        %Task4CClientRobotB.Position{x: x, y: y, facing: facing} = robot
        # IO.puts("exited if")
      end
    else
      robot = left(robot)
      %Task4CClientRobotB.Position{x: x, y: y, facing: facing} = robot

      is_obs =
        Task4CClientRobotB.PhoenixSocketClient.send_robot_status(
          channel_status,
          channel_position,
          robot
        )

      if(is_obs) do
        robot = left(robot)
        %Task4CClientRobotB.Position{x: x, y: y, facing: facing} = robot

        is_obs =
          Task4CClientRobotB.PhoenixSocketClient.send_robot_status(
            channel_status,
            channel_position,
            robot
          )

        robot = move(robot)
        %Task4CClientRobotB.Position{x: x, y: y, facing: facing} = robot

        is_obs =
          Task4CClientRobotB.PhoenixSocketClient.send_robot_status(
            channel_status,
            channel_position,
            robot
          )

        robot = right(robot)
        %Task4CClientRobotB.Position{x: x, y: y, facing: facing} = robot

        is_obs =
          Task4CClientRobotB.PhoenixSocketClient.send_robot_status(
            channel_status,
            channel_position,
            robot
          )

        if(is_obs) do
          objInY_south(
            %Task4CClientRobotB.Position{x: x, y: y, facing: facing} = robot,
            goal_x,
            goal_y,
            channel_status,
            channel_position,
            repeat = 0,
            goal_list
          )
        else
          robot = move(robot)
          %Task4CClientRobotB.Position{x: x, y: y, facing: facing} = robot

          # is_obs = Task4CClientRobotB.PhoenixSocketClient.send_robot_status(channel_status, channel_position,robot)
          correct_X(robot, goal_x, goal_y, channel_status, channel_position, goal_list)
        end

        %Task4CClientRobotB.Position{x: x, y: y, facing: facing} = robot
      else
        robot = move(robot)
        %Task4CClientRobotB.Position{x: x, y: y, facing: facing} = robot

        is_obs =
          Task4CClientRobotB.PhoenixSocketClient.send_robot_status(
            channel_status,
            channel_position,
            robot
          )

        robot = right(robot)
        %Task4CClientRobotB.Position{x: x, y: y, facing: facing} = robot

        is_obs =
          Task4CClientRobotB.PhoenixSocketClient.send_robot_status(
            channel_status,
            channel_position,
            robot
          )

        if is_obs do
          repeat = 0
          objInX_west(robot, goal_x, goal_y, channel_status, channel_position, repeat, goal_list)
        else
          robot = move(robot)
          %Task4CClientRobotB.Position{x: x, y: y, facing: facing} = robot

          # is_obs = Task4CClientRobotB.PhoenixSocketClient.send_robot_status(channel_status, channel_position,robot)
          # IO.inspect(robot)
          go_to_goal(robot, goal_x, goal_y, channel_status, channel_position, goal_list)
        end

        %Task4CClientRobotB.Position{x: x, y: y, facing: facing} = robot
        # IO.puts("exited else")
      end
    end

    %Task4CClientRobotB.Position{x: x, y: y, facing: facing} = robot
    # call the base go_to_goal func at this point
    # go_to_goal(robot, goal_x, goal_y, channel_status, channel_position,goal_list)
  end

  def objInX_east(
        %Task4CClientRobotB.Position{x: x, y: y, facing: facing} = robot,
        goal_x,
        goal_y,
        channel_status,
        channel_position,
        repeat,
        goal_list
      ) do
    # make sure bot is facing east before running this func
    # IO.puts("in east")

    %Task4CClientRobotB.Position{x: x, y: y, facing: facing} = robot

    # turn, move left and face west
    # turn, move right and face east//
    if y == :a or repeat == 1 do
      # boundry case
      # IO.puts("in y=a")
      robot = left(robot)
      %Task4CClientRobotB.Position{x: x, y: y, facing: facing} = robot

      is_obs =
        Task4CClientRobotB.PhoenixSocketClient.send_robot_status(
          channel_status,
          channel_position,
          robot
        )

      if(is_obs) do
        robot = left(robot)
        %Task4CClientRobotB.Position{x: x, y: y, facing: facing} = robot

        is_obs =
          Task4CClientRobotB.PhoenixSocketClient.send_robot_status(
            channel_status,
            channel_position,
            robot
          )

        robot = move(robot)
        %Task4CClientRobotB.Position{x: x, y: y, facing: facing} = robot

        is_obs =
          Task4CClientRobotB.PhoenixSocketClient.send_robot_status(
            channel_status,
            channel_position,
            robot
          )

        robot = right(robot)
        %Task4CClientRobotB.Position{x: x, y: y, facing: facing} = robot

        is_obs =
          Task4CClientRobotB.PhoenixSocketClient.send_robot_status(
            channel_status,
            channel_position,
            robot
          )

        if(is_obs) do
          objInY_north(
            %Task4CClientRobotB.Position{x: x, y: y, facing: facing} = robot,
            goal_x,
            goal_y,
            channel_status,
            channel_position,
            repeat = 0,
            goal_list
          )
        else
          robot = move(robot)
          %Task4CClientRobotB.Position{x: x, y: y, facing: facing} = robot

          # is_obs = Task4CClientRobotB.PhoenixSocketClient.send_robot_status(channel_status, channel_position,robot)
          correct_X(robot, goal_x, goal_y, channel_status, channel_position, goal_list)
        end

        %Task4CClientRobotB.Position{x: x, y: y, facing: facing} = robot
      else
        robot = move(robot)
        %Task4CClientRobotB.Position{x: x, y: y, facing: facing} = robot

        is_obs =
          Task4CClientRobotB.PhoenixSocketClient.send_robot_status(
            channel_status,
            channel_position,
            robot
          )

        robot = right(robot)
        %Task4CClientRobotB.Position{x: x, y: y, facing: facing} = robot

        is_obs =
          Task4CClientRobotB.PhoenixSocketClient.send_robot_status(
            channel_status,
            channel_position,
            robot
          )

        if is_obs do
          repeat = 1
          objInX_east(robot, goal_x, goal_y, channel_status, channel_position, repeat,goal_list)
        else
          robot = move(robot)
          %Task4CClientRobotB.Position{x: x, y: y, facing: facing} = robot
          go_to_goal(robot, goal_x, goal_y, channel_status, channel_position, goal_list)
        end

        %Task4CClientRobotB.Position{x: x, y: y, facing: facing} = robot

        # is_obs = Task4CClientRobotB.PhoenixSocketClient.send_robot_status(channel_status, channel_position,robot)
        # IO.puts("exited else")
      end
    else
      # IO.puts("in else")
      #########################
      robot = left(robot)
      %Task4CClientRobotB.Position{x: x, y: y, facing: facing} = robot

      is_obs =
        Task4CClientRobotB.PhoenixSocketClient.send_robot_status(
          channel_status,
          channel_position,
          robot
        )

      if(is_obs) do
        # IO.puts("in isobs")
        robot = right(robot)
        %Task4CClientRobotB.Position{x: x, y: y, facing: facing} = robot

        is_obs =
          Task4CClientRobotB.PhoenixSocketClient.send_robot_status(
            channel_status,
            channel_position,
            robot
          )

        robot = move(robot)
        %Task4CClientRobotB.Position{x: x, y: y, facing: facing} = robot

        is_obs =
          Task4CClientRobotB.PhoenixSocketClient.send_robot_status(
            channel_status,
            channel_position,
            robot
          )

        robot = left(robot)
        %Task4CClientRobotB.Position{x: x, y: y, facing: facing} = robot

        is_obs =
          Task4CClientRobotB.PhoenixSocketClient.send_robot_status(
            channel_status,
            channel_position,
            robot
          )

        if(is_obs) do
          objInY_south(
            %Task4CClientRobotB.Position{x: x, y: y, facing: facing} = robot,
            goal_x,
            goal_y,
            channel_status,
            channel_position,
            repeat = 0,
            goal_list
          )
        else
          robot = move(robot)
          %Task4CClientRobotB.Position{x: x, y: y, facing: facing} = robot

          # is_obs = Task4CClientRobotB.PhoenixSocketClient.send_robot_status(channel_status, channel_position,robot)
          correct_X(robot, goal_x, goal_y, channel_status, channel_position, goal_list)
        end

        %Task4CClientRobotB.Position{x: x, y: y, facing: facing} = robot
      else
        # IO.puts("in else isobs")
        robot = move(robot)
        %Task4CClientRobotB.Position{x: x, y: y, facing: facing} = robot

        is_obs =
          Task4CClientRobotB.PhoenixSocketClient.send_robot_status(
            channel_status,
            channel_position,
            robot
          )

        ##################
        robot = right(robot)

        is_obs =
          Task4CClientRobotB.PhoenixSocketClient.send_robot_status(
            channel_status,
            channel_position,
            robot
          )

        %Task4CClientRobotB.Position{x: x, y: y, facing: facing} = robot

        if is_obs do
          # IO.puts("in unwanted")
          repeat = 0
          objInX_east(robot, goal_x, goal_y, channel_status, channel_position, repeat,goal_list)
        else
          # IO.puts("in wanted")
          robot = move(robot)
          %Task4CClientRobotB.Position{x: x, y: y, facing: facing} = robot

          # is_obs = Task4CClientRobotB.PhoenixSocketClient.send_robot_status(channel_status, channel_position,robot)
          go_to_goal(robot, goal_x, goal_y, channel_status, channel_position, goal_list)
        end

        %Task4CClientRobotB.Position{x: x, y: y, facing: facing} = robot
        # IO.puts("exited if")
      end
    end

    %Task4CClientRobotB.Position{x: x, y: y, facing: facing} = robot
    # call the base go_to_goal func at this point
    # go_to_goal(robot, goal_x, goal_y, channel_status, channel_position,goal_list)
  end

  @doc """
  Provide GOAL positions to the robot as given location of [(x1, y1),(x2, y2),..] and plan the path from START to these locations.
  Make a call to ToyRobot.PhoenixSocketClient.send_robot_status/2 to get the indication of obstacle presence ahead of the robot.
  """
  def stop(robot, goal_locs, channel_status, channel_position,goalssssss) do
    goal_locs =
      if Enum.empty?(goal_locs) == false do
        goal1 = Enum.at(goal_locs, 0)
        goal_list = Enum.at(goalssssss,0)
        # goal_x = goal1["x"]
        # goal_y = String.to_atom(goal1["y"])
        goal_x = String.to_integer(Enum.at(goal1, 0))
        goal_y = String.to_atom(Enum.at(goal1, 1))
        # IO.inspect({goal_x, goal_y})
        # goal_list = []
        robot_old = go_to_goal(robot, goal_x, goal_y, channel_status, channel_position,goal_list)
        ##########################################################################################################################
        #testin function for line following with communication
        #will move the robot in real life.

        #comment the line robot_old = go_to_goal(robot, goal_x, goal_y, channel_status, channel_position,goal_list) above and uncomment below


        # robot_test = line_follow_and_communication_test(robot,goal_x,goal_y,channel_status,channel_position)
        ##########################################################################################################################
        # IO.inspect(robot)
        robot_corr = get_correct_robot_position(channel_position)
        # IO.inspect(robot_corr)
        robot = %Task4CClientRobotB.Position{
          x: robot_corr["x"],
          y: String.to_atom(robot_corr["y"]),
          facing: String.to_atom(robot_corr["face"])
        }
        goal_locs = List.delete_at(goal_locs, 0)
        goalssssss = List.delete_at(goalssssss,0)
        ################################################## recursive call commented for testing purpose, uncomment later ##############################
        # stop(robot, goal_locs, channel_status, channel_position,goalssssss)
      else
        goal_locs
      end

    goal_locs
  end
  def line_follow_and_communication_test(robot,goal_x,goal_y,channel_status,channel_position) do
    robot = move(robot)
    is_obs =
      Task4CClientRobotA.PhoenixSocketClient.send_robot_status(
        channel_status,
        channel_position,
        robot
      )
    robot = move(robot)
    is_obs =
      Task4CClientRobotA.PhoenixSocketClient.send_robot_status(
        channel_status,
        channel_position,
        robot
      )
    # robot = right(robot)
    # is_obs =
    #   Task4CClientRobotA.PhoenixSocketClient.send_robot_status(
    #     channel_status,
    #     channel_position,
    #     robot
    #   )
    # robot = move(robot)
    # is_obs =
    #   Task4CClientRobotA.PhoenixSocketClient.send_robot_status(
    #     channel_status,
    #     channel_position,
    #     robot
    #   )
    # robot = left(robot)
    # is_obs =
    #   Task4CClientRobotA.PhoenixSocketClient.send_robot_status(
    #     channel_status,
    #     channel_position,
    #     robot
    #   )
    robot
  end
  def get_correct_robot_position(channel_position) do
    {:ok, robot_position} = PhoenixClient.Channel.push(channel_position, "give_robb_pos", "nil")
    robot_position
  end

  def check_if_goal_reached(goal_list, robot) do
    x = Integer.to_string(robot.x)
    y = Atom.to_string(robot.y)
    goal = [x, y]
    bool = Enum.member?(goal_list, goal)
  end

  def go_to_goal(
        %Task4CClientRobotB.Position{x: x, y: y, facing: facing} = robot,
        goal_x,
        goal_y,
        channel_status,
        channel_position,
        goal_list
      ) do
    bool = check_if_goal_reached(goal_list, robot)
    ##############################################
    if bool == true do
      is_obs =
        Task4CClientRobotB.PhoenixSocketClient.send_robot_status(
          channel_status,
          channel_position,
          robot
        )

      # IO.puts("go to goal b")
      # IO.inspect(robot)
      robot
      # {:ok,robot}
    else
      is_obs =
        Task4CClientRobotB.PhoenixSocketClient.send_robot_status(
          channel_status,
          channel_position,
          robot
        )

      # IO.inspect(robot)
      # IO.puts("----")
      if y < goal_y do
        if facing != :north do
          robot = right(robot)
          # is_obs = check_for_obs(robot,channel_status, channel_position)
          # send_robot_status(robot, channel_status, channel_position)
          go_to_goal(robot, goal_x, goal_y, channel_status, channel_position, goal_list)
        else
          # is_obs = Task4CClientRobotB.PhoenixSocketClient.send_robot_status(channel_status, channel_position,robot)
          # is_obs = Task4CClientRobotB.PhoenixSocketClient.send_robot_status(channel_status, channel_position,robot)
          if(is_obs) do
            #  IO.put("Obstacle at #{x}, #{y + 1}")
            # IO.puts("Obstacle at #{x}, #{y}, #{facing}")
            objInY_north(robot, goal_x, goal_y, channel_status, channel_position, repeat = 0,goal_list)
          else
            # %Task4CClientRobotB.Position{x: x, y: y, facing: facing} = robot
            # is_obs = Task4CClientRobotB.PhoenixSocketClient.send_robot_status(channel_status, channel_position,robot)
            robot = move(robot)

            # is_obs = Task4CClientRobotB.PhoenixSocketClient.send_robot_status(channel_status, channel_position,robot)
            # send_robot_status(robot, channel_status, channel_position)
            go_to_goal(robot, goal_x, goal_y, channel_status, channel_position, goal_list)
          end
        end
      else
        if y > goal_y do
          if facing != :south do
            robot = right(robot)
            # is_obs = check_for_obs(robot,channel_status, channel_position)
            # send_robot_status(robot, channel_status, channel_position)
            go_to_goal(robot, goal_x, goal_y, channel_status, channel_position, goal_list)
          else
            # is_obs = check_for_obs(robot,channel_status, channel_position)
            if(is_obs) do
              # IO.put("Obstacle at #{x}, #{y - 1}")
              # IO.puts("Obstacle at #{x}, #{y}, #{facing}")
              objInY_south(robot, goal_x, goal_y, channel_status, channel_position, repeat = 0,goal_list)
            else
              robot = move(robot)
              go_to_goal(robot, goal_x, goal_y, channel_status, channel_position, goal_list)
            end

            # send_robot_status(robot, channel_status, channel_position)
          end
        else
          if x > goal_x do
            if facing != :west do
              robot = right(robot)
              # send_robot_status(robot, channel_status, channel_position)
              # is_obs = check_for_obs(robot,channel_status, channel_position)
              go_to_goal(robot, goal_x, goal_y, channel_status, channel_position, goal_list)
            else
              # is_obs = check_for_obs(robot,channel_status, channel_position)
              if(is_obs) do
                # IO.puts("Obstacle at #{x}, #{y}, #{facing}")
                objInX_west(robot, goal_x, goal_y, channel_status, channel_position, repeat = 0,goal_list)
              else
                robot = move(robot)
                go_to_goal(robot, goal_x, goal_y, channel_status, channel_position, goal_list)
              end
            end

            # send_robot_status(robot, channel_status, channel_position)
          else
            if x < goal_x do
              # is_obs = Task4CClientRobotB.PhoenixSocketClient.send_robot_status(channel_status, channel_position,robot)
              if facing != :east do
                robot = right(robot)
                # send_robot_status(robot, channel_status, channel_position)
                # is_obs = check_for_obs(robot,channel_status, channel_position)
                go_to_goal(robot, goal_x, goal_y, channel_status, channel_position, goal_list)
              else
                # is_obs = check_for_obs(robot,channel_status, channel_position)
                if(is_obs) do
                  # IO.put("Obstacle at #{x + 1}, #{y}")
                  # IO.puts("Obstacle at #{x}, #{y}, #{facing}")
                  # -----
                  objInX_east(robot, goal_x, goal_y, channel_status, channel_position, repeat = 0,goal_list)
                else
                  robot = move(robot)
                  go_to_goal(robot, goal_x, goal_y, channel_status, channel_position, goal_list)
                end
              end

              # send_robot_status(robot, channel_status, channel_position)
            else
              is_obs =
                Task4CClientRobotB.PhoenixSocketClient.send_robot_status(
                  channel_status,
                  channel_position,
                  robot
                )

              # {:ok,robot}
            end
          end
        end
      end

      # --> end for the main if - else
    end

    # --> end for the main go_to_goal function
  end

  def send_goal_loc(channel_position, goal_location) do
    {:ok, reply} =
      PhoenixClient.Channel.push(channel_position, "incoming_goal_loc_b", goal_location)
  end

  @doc """
  Provides the report of the robot's current position

  Examples:

      iex> {:ok, robot} = Task4CClientRobotB.place(2, :b, :west)
      iex> Task4CClientRobotB.report(robot)
      {2, :b, :west}
  """
  def report(%Task4CClientRobotB.Position{x: x, y: y, facing: facing} = _robot) do
    {x, y, facing}
  end

  @directions_to_the_right %{north: :east, east: :south, south: :west, west: :north}
  @doc """
  Rotates the robot to the right
  """
  def right(%Task4CClientRobotB.Position{facing: facing} = robot) do
    %Task4CClientRobotB.Position{robot | facing: @directions_to_the_right[facing]}
  end

  @directions_to_the_left Enum.map(@directions_to_the_right, fn {from, to} -> {to, from} end)
  @doc """
  Rotates the robot to the left
  """
  def left(%Task4CClientRobotB.Position{facing: facing} = robot) do
    %Task4CClientRobotB.Position{robot | facing: @directions_to_the_left[facing]}
  end

  @doc """
  Moves the robot to the north, but prevents it to fall
  """
  def move(%Task4CClientRobotB.Position{x: _, y: y, facing: :north} = robot)
      when y < @table_top_y do
        follow_line()
    %Task4CClientRobotB.Position{
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
  def move(%Task4CClientRobotB.Position{x: x, y: _, facing: :east} = robot)
      when x < @table_top_x do
        follow_line()
    %Task4CClientRobotB.Position{robot | x: x + 1}
  end

  @doc """
  Moves the robot to the south, but prevents it to fall
  """
  def move(%Task4CClientRobotB.Position{x: _, y: y, facing: :south} = robot) when y > :a do
    follow_line()
    %Task4CClientRobotB.Position{
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
  def move(%Task4CClientRobotB.Position{x: x, y: _, facing: :west} = robot) when x > 1 do
    follow_line()
    %Task4CClientRobotB.Position{robot | x: x - 1}
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
