defmodule Task4CClientRobotA do
  require Logger
  use Bitwise
  alias Circuits.GPIO
  # max x-coordinate of table top
  @table_top_x 6
  # max y-coordinate of table top
  @table_top_y :f
  # mapping of y-coordinates
  @robot_map_y_atom_to_num %{:a => 1, :b => 2, :c => 3, :d => 4, :e => 5, :f => 6}
  defmodule SortedListStruct do
    @derive Jason.Encoder
    defstruct value: -1, index: -1
  end

  @sensor_pins [cs: 5, clock: 25, address: 24, dataout: 23]
  @ir_pins [dr: 16, dl: 19]
  @motor_pins [lf: 12, lb: 13, rf: 20, rb: 21]
  @pwm_pins [enl: 6, enr: 26]
  @servo_a_pin 27
  @servo_b_pin 22

  @ref_atoms [:cs, :clock, :address, :dataout]
  @lf_sensor_data %{sensor0: 0, sensor1: 0, sensor2: 0, sensor3: 0, sensor4: 0, sensor5: 0}
  @lf_sensor_map %{
    0 => :sensor0,
    1 => :sensor1,
    2 => :sensor2,
    3 => :sensor3,
    4 => :sensor4,
    5 => :sensor5
  }

  @forward [0, 1, 1, 0]
  @backward [1, 0, 0, 1]
  @left [0, 1, 0, 1]
  @right [1, 0, 1, 0]
  @stop [0, 0, 0, 0]

  @duty_cycles [125, 0]
  @duty_cycles_left [150, 0]
  @pwm_frequency 50
  @new_motor_pins [lf: 12, rb: 20]

  @left_const 90
  @right_const 90
  @only_right [1, 1]

  @only_left [0, 1, 0, 0]
  @kp 8
  @kd 7
  @ki 0.01

  @caplow 80
  @caphigh 120
  @caphigh 120
  #############################################################################################################################
  ############################################## Algorithm ####################################################################
  #############################################################################################################################
  def correct_X(
        %Task4CClientRobotA.Position{x: x, y: y, facing: facing} = robot,
        goal_x,
        goal_y,
        channel_status,
        channel_position,
        goal_list
      ) do
    %Task4CClientRobotA.Position{x: x, y: y, facing: facing} = robot

    if(goal_x == x) do
      # is_obs = Task4CClientRobotA.PhoenixSocketClient.send_robot_status(channel_status,channel_position,robot)
      go_to_goal(robot, goal_x, goal_y, channel_status, channel_position, goal_list)
      {:ok, robot}
    else
      is_obs =
        Task4CClientRobotA.PhoenixSocketClient.send_robot_status(
          channel_status,
          channel_position,
          robot
        )

      if x > goal_x do
        if facing != :west do
          robot =
            if facing == :north do
              robot = left(robot)
              %Task4CClientRobotA.Position{x: x, y: y, facing: facing} = robot
            else
              robot = right(robot)
              %Task4CClientRobotA.Position{x: x, y: y, facing: facing} = robot
            end

          %Task4CClientRobotA.Position{x: x, y: y, facing: facing} = robot
          # send_robot_status(robot, channel_status, channel_position)
          # is_obs = check_for_obs(robot,channel_status, channel_position)
          correct_X(robot, goal_x, goal_y, channel_status, channel_position, goal_list)
        else
          %Task4CClientRobotA.Position{x: x, y: y, facing: facing} = robot
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

            %Task4CClientRobotA.Position{x: x, y: y, facing: facing} = robot
          else
            robot = move(robot)
            %Task4CClientRobotA.Position{x: x, y: y, facing: facing} = robot
            correct_X(robot, goal_x, goal_y, channel_status, channel_position, goal_list)
          end
        end

        # send_robot_status(robot, channel_status, channel_position)
      else
        if x < goal_x do
          # is_obs = Task4CClientRobotA.PhoenixSocketClient.send_robot_status(channel_status,channel_position,robot)
          %Task4CClientRobotA.Position{x: x, y: y, facing: facing} = robot

          if facing != :east do
            robot =
              if facing == :south do
                robot = left(robot)
                %Task4CClientRobotA.Position{x: x, y: y, facing: facing} = robot
              else
                robot = right(robot)
                %Task4CClientRobotA.Position{x: x, y: y, facing: facing} = robot
              end

            %Task4CClientRobotA.Position{x: x, y: y, facing: facing} = robot
            # send_robot_status(robot, channel_status, channel_position)
            # is_obs = check_for_obs(robot,channel_status, channel_position)
            correct_X(robot, goal_x, goal_y, channel_status, channel_position, goal_list)
          else
            %Task4CClientRobotA.Position{x: x, y: y, facing: facing} = robot
            # is_obs = check_for_obs(robot,channel_status, channel_position)

            if(is_obs) do
              # IO.put("Obstacle at #{x + 1}, #{y}")
              # IO.puts("Obstacle at #{x}, #{y}, #{facing}")
              objInX_east(
                robot,
                goal_x,
                goal_y,
                channel_status,
                channel_position,
                repeat = 0,
                goal_list
              )

              %Task4CClientRobotA.Position{x: x, y: y, facing: facing} = robot
            else
              robot = move(robot)
              %Task4CClientRobotA.Position{x: x, y: y, facing: facing} = robot
              correct_X(robot, goal_x, goal_y, channel_status, channel_position, goal_list)
            end
          end
        end
      end
    end
  end

  def objInY_north(
        %Task4CClientRobotA.Position{x: x, y: y, facing: facing} = robot,
        goal_x,
        goal_y,
        channel_status,
        channel_position,
        repeat,
        goal_list
      ) do
    %Task4CClientRobotA.Position{x: x, y: y, facing: facing} = robot

    # make sure bot is facing north
    # IO.puts("in north")
    # turn and right and face north
    # turn and move left and face north
    if x == 1 or repeat == 1 do
      # IO.puts("in 1")
      robot = right(robot)
      %Task4CClientRobotA.Position{x: x, y: y, facing: facing} = robot

      is_obs =
        Task4CClientRobotA.PhoenixSocketClient.send_robot_status(
          channel_status,
          channel_position,
          robot
        )

      if(is_obs) do
        robot = right(robot)
        %Task4CClientRobotA.Position{x: x, y: y, facing: facing} = robot

        is_obs =
          Task4CClientRobotA.PhoenixSocketClient.send_robot_status(
            channel_status,
            channel_position,
            robot
          )

        robot = move(robot)
        %Task4CClientRobotA.Position{x: x, y: y, facing: facing} = robot

        is_obs =
          Task4CClientRobotA.PhoenixSocketClient.send_robot_status(
            channel_status,
            channel_position,
            robot
          )

        robot = left(robot)
        %Task4CClientRobotA.Position{x: x, y: y, facing: facing} = robot

        is_obs =
          Task4CClientRobotA.PhoenixSocketClient.send_robot_status(
            channel_status,
            channel_position,
            robot
          )

        if(is_obs) do
          objInX_east(
            %Task4CClientRobotA.Position{x: x, y: y, facing: facing} = robot,
            goal_x,
            goal_y,
            channel_status,
            channel_position,
            repeat = 0,
            goal_list
          )
        else
          robot = move(robot)
          %Task4CClientRobotA.Position{x: x, y: y, facing: facing} = robot

          # is_obs = Task4CClientRobotA.PhoenixSocketClient.send_robot_status(channel_status,channel_position,robot)
          go_to_goal(robot, goal_x, goal_y, channel_status, channel_position, goal_list)
        end

        %Task4CClientRobotA.Position{x: x, y: y, facing: facing} = robot
      else
        robot = move(robot)
        %Task4CClientRobotA.Position{x: x, y: y, facing: facing} = robot

        is_obs =
          Task4CClientRobotA.PhoenixSocketClient.send_robot_status(
            channel_status,
            channel_position,
            robot
          )

        robot = left(robot)

        is_obs =
          Task4CClientRobotA.PhoenixSocketClient.send_robot_status(
            channel_status,
            channel_position,
            robot
          )

        %Task4CClientRobotA.Position{x: x, y: y, facing: facing} = robot

        if is_obs do
          repeat = 1
          objInY_north(robot, goal_x, goal_y, channel_status, channel_position, repeat, goal_list)
        else
          robot = move(robot)
          %Task4CClientRobotA.Position{x: x, y: y, facing: facing} = robot

          # is_obs = Task4CClientRobotA.PhoenixSocketClient.send_robot_status(channel_status,channel_position,robot)
          if x != goal_x do
            correct_X(robot, goal_x, goal_y, channel_status, channel_position, goal_list)
          else
            go_to_goal(robot, goal_x, goal_y, channel_status, channel_position, goal_list)
          end
        end

        %Task4CClientRobotA.Position{x: x, y: y, facing: facing} = robot

        # IO.puts("exited if")
      end
    else
      # IO.puts("in 2")
      robot = left(robot)
      %Task4CClientRobotA.Position{x: x, y: y, facing: facing} = robot

      is_obs =
        Task4CClientRobotA.PhoenixSocketClient.send_robot_status(
          channel_status,
          channel_position,
          robot
        )

      if(is_obs) do
        robot = left(robot)
        %Task4CClientRobotA.Position{x: x, y: y, facing: facing} = robot

        is_obs =
          Task4CClientRobotA.PhoenixSocketClient.send_robot_status(
            channel_status,
            channel_position,
            robot
          )

        robot = move(robot)
        %Task4CClientRobotA.Position{x: x, y: y, facing: facing} = robot

        is_obs =
          Task4CClientRobotA.PhoenixSocketClient.send_robot_status(
            channel_status,
            channel_position,
            robot
          )

        robot = right(robot)
        %Task4CClientRobotA.Position{x: x, y: y, facing: facing} = robot

        is_obs =
          Task4CClientRobotA.PhoenixSocketClient.send_robot_status(
            channel_status,
            channel_position,
            robot
          )

        if(is_obs) do
          objInX_west(
            %Task4CClientRobotA.Position{x: x, y: y, facing: facing} = robot,
            goal_x,
            goal_y,
            channel_status,
            channel_position,
            repeat = 0,
            goal_list
          )
        else
          robot = move(robot)
          %Task4CClientRobotA.Position{x: x, y: y, facing: facing} = robot

          # is_obs = Task4CClientRobotA.PhoenixSocketClient.send_robot_status(channel_status,channel_position,robot)
          go_to_goal(robot, goal_x, goal_y, channel_status, channel_position, goal_list)
        end

        %Task4CClientRobotA.Position{x: x, y: y, facing: facing} = robot
      else
        robot = move(robot)
        %Task4CClientRobotA.Position{x: x, y: y, facing: facing} = robot

        is_obs =
          Task4CClientRobotA.PhoenixSocketClient.send_robot_status(
            channel_status,
            channel_position,
            robot
          )

        robot = right(robot)
        %Task4CClientRobotA.Position{x: x, y: y, facing: facing} = robot

        is_obs =
          Task4CClientRobotA.PhoenixSocketClient.send_robot_status(
            channel_status,
            channel_position,
            robot
          )

        if is_obs do
          repeat = 0
          objInY_north(robot, goal_x, goal_y, channel_status, channel_position, repeat, goal_list)
        else
          robot = move(robot)

          # is_obs = Task4CClientRobotA.PhoenixSocketClient.send_robot_status(channel_status,channel_position,robot)
          %Task4CClientRobotA.Position{x: x, y: y, facing: facing} = robot

          if x != goal_x do
            correct_X(robot, goal_x, goal_y, channel_status, channel_position, goal_list)
          else
            go_to_goal(robot, goal_x, goal_y, channel_status, channel_position, goal_list)
          end
        end

        %Task4CClientRobotA.Position{x: x, y: y, facing: facing} = robot
        # IO.puts("exited else")
      end
    end

    %Task4CClientRobotA.Position{x: x, y: y, facing: facing} = robot
    # IO.puts("#{x}, #{y}, #{facing}")
    # call the base go_to_goal func at this point
  end

  def objInY_south(
        %Task4CClientRobotA.Position{x: x, y: y, facing: facing} = robot,
        goal_x,
        goal_y,
        channel_status,
        channel_position,
        repeat,
        goal_list
      ) do
    %Task4CClientRobotA.Position{x: x, y: y, facing: facing} = robot
    # turn, move left and face south
    # turn, move right and go south
    if x == 1 or repeat == 1 do
      robot = left(robot)
      %Task4CClientRobotA.Position{x: x, y: y, facing: facing} = robot

      is_obs =
        Task4CClientRobotA.PhoenixSocketClient.send_robot_status(
          channel_status,
          channel_position,
          robot
        )

      if(is_obs) do
        robot = left(robot)
        %Task4CClientRobotA.Position{x: x, y: y, facing: facing} = robot

        is_obs =
          Task4CClientRobotA.PhoenixSocketClient.send_robot_status(
            channel_status,
            channel_position,
            robot
          )

        robot = move(robot)
        %Task4CClientRobotA.Position{x: x, y: y, facing: facing} = robot

        is_obs =
          Task4CClientRobotA.PhoenixSocketClient.send_robot_status(
            channel_status,
            channel_position,
            robot
          )

        robot = right(robot)
        %Task4CClientRobotA.Position{x: x, y: y, facing: facing} = robot

        is_obs =
          Task4CClientRobotA.PhoenixSocketClient.send_robot_status(
            channel_status,
            channel_position,
            robot
          )

        if(is_obs) do
          objInX_east(
            %Task4CClientRobotA.Position{x: x, y: y, facing: facing} = robot,
            goal_x,
            goal_y,
            channel_status,
            channel_position,
            repeat = 0,
            goal_list
          )
        else
          robot = move(robot)
          %Task4CClientRobotA.Position{x: x, y: y, facing: facing} = robot

          # is_obs = Task4CClientRobotA.PhoenixSocketClient.send_robot_status(channel_status,channel_position,robot)
          go_to_goal(robot, goal_x, goal_y, channel_status, channel_position, goal_list)
        end

        %Task4CClientRobotA.Position{x: x, y: y, facing: facing} = robot
      else
        robot = move(robot)
        %Task4CClientRobotA.Position{x: x, y: y, facing: facing} = robot

        is_obs =
          Task4CClientRobotA.PhoenixSocketClient.send_robot_status(
            channel_status,
            channel_position,
            robot
          )

        robot = right(robot)
        %Task4CClientRobotA.Position{x: x, y: y, facing: facing} = robot

        is_obs =
          Task4CClientRobotA.PhoenixSocketClient.send_robot_status(
            channel_status,
            channel_position,
            robot
          )

        if is_obs do
          repeat = 1
          objInY_south(robot, goal_x, goal_y, channel_status, channel_position, repeat, goal_list)
        else
          robot = move(robot)
          %Task4CClientRobotA.Position{x: x, y: y, facing: facing} = robot

          # is_obs = Task4CClientRobotA.PhoenixSocketClient.send_robot_status(channel_status,channel_position,robot)
          if x != goal_x do
            correct_X(robot, goal_x, goal_y, channel_status, channel_position, goal_list)
          else
            go_to_goal(robot, goal_x, goal_y, channel_status, channel_position, goal_list)
          end
        end

        %Task4CClientRobotA.Position{x: x, y: y, facing: facing} = robot
        # IO.puts("exited else")
      end
    else
      robot = right(robot)
      %Task4CClientRobotA.Position{x: x, y: y, facing: facing} = robot

      is_obs =
        Task4CClientRobotA.PhoenixSocketClient.send_robot_status(
          channel_status,
          channel_position,
          robot
        )

      if(is_obs) do
        robot = right(robot)
        %Task4CClientRobotA.Position{x: x, y: y, facing: facing} = robot

        is_obs =
          Task4CClientRobotA.PhoenixSocketClient.send_robot_status(
            channel_status,
            channel_position,
            robot
          )

        robot = move(robot)
        %Task4CClientRobotA.Position{x: x, y: y, facing: facing} = robot

        is_obs =
          Task4CClientRobotA.PhoenixSocketClient.send_robot_status(
            channel_status,
            channel_position,
            robot
          )

        robot = left(robot)
        %Task4CClientRobotA.Position{x: x, y: y, facing: facing} = robot

        is_obs =
          Task4CClientRobotA.PhoenixSocketClient.send_robot_status(
            channel_status,
            channel_position,
            robot
          )

        if(is_obs) do
          objInX_west(
            %Task4CClientRobotA.Position{x: x, y: y, facing: facing} = robot,
            goal_x,
            goal_y,
            channel_status,
            channel_position,
            repeat = 0,
            goal_list
          )
        else
          robot = move(robot)
          %Task4CClientRobotA.Position{x: x, y: y, facing: facing} = robot

          # is_obs = Task4CClientRobotA.PhoenixSocketClient.send_robot_status(channel_status,channel_position,robot)
          go_to_goal(robot, goal_x, goal_y, channel_status, channel_position, goal_list)
        end

        %Task4CClientRobotA.Position{x: x, y: y, facing: facing} = robot
      else
        robot = move(robot)
        %Task4CClientRobotA.Position{x: x, y: y, facing: facing} = robot

        is_obs =
          Task4CClientRobotA.PhoenixSocketClient.send_robot_status(
            channel_status,
            channel_position,
            robot
          )

        robot = left(robot)

        is_obs =
          Task4CClientRobotA.PhoenixSocketClient.send_robot_status(
            channel_status,
            channel_position,
            robot
          )

        %Task4CClientRobotA.Position{x: x, y: y, facing: facing} = robot

        if is_obs do
          repeat = 0
          objInY_south(robot, goal_x, goal_y, channel_status, channel_position, repeat, goal_list)
        else
          robot = move(robot)
          %Task4CClientRobotA.Position{x: x, y: y, facing: facing} = robot

          # is_obs = Task4CClientRobotA.PhoenixSocketClient.send_robot_status(channel_status,channel_position,robot)
          if x != goal_x do
            correct_X(robot, goal_x, goal_y, channel_status, channel_position, goal_list)
          else
            go_to_goal(robot, goal_x, goal_y, channel_status, channel_position, goal_list)
          end
        end

        %Task4CClientRobotA.Position{x: x, y: y, facing: facing} = robot
        # IO.puts("exited if")
      end
    end

    %Task4CClientRobotA.Position{x: x, y: y, facing: facing} = robot
    # call the base go_to_goal func at this point
    # go_to_goal(robot, goal_x, goal_y, channel_status, channel_position,goal_list)
  end

  def objInX_west(
        %Task4CClientRobotA.Position{x: x, y: y, facing: facing} = robot,
        goal_x,
        goal_y,
        channel_status,
        channel_position,
        repeat,
        goal_list
      ) do
    %Task4CClientRobotA.Position{x: x, y: y, facing: facing} = robot
    # turn, move left and face east
    # turn, move right and go south
    if y == :a or repeat == 1 do
      robot = right(robot)
      %Task4CClientRobotA.Position{x: x, y: y, facing: facing} = robot

      is_obs =
        Task4CClientRobotA.PhoenixSocketClient.send_robot_status(
          channel_status,
          channel_position,
          robot
        )

      if(is_obs) do
        robot = right(robot)
        %Task4CClientRobotA.Position{x: x, y: y, facing: facing} = robot

        is_obs =
          Task4CClientRobotA.PhoenixSocketClient.send_robot_status(
            channel_status,
            channel_position,
            robot
          )

        robot = move(robot)
        %Task4CClientRobotA.Position{x: x, y: y, facing: facing} = robot

        is_obs =
          Task4CClientRobotA.PhoenixSocketClient.send_robot_status(
            channel_status,
            channel_position,
            robot
          )

        robot = left(robot)
        %Task4CClientRobotA.Position{x: x, y: y, facing: facing} = robot

        is_obs =
          Task4CClientRobotA.PhoenixSocketClient.send_robot_status(
            channel_status,
            channel_position,
            robot
          )

        if(is_obs) do
          objInY_north(
            %Task4CClientRobotA.Position{x: x, y: y, facing: facing} = robot,
            goal_x,
            goal_y,
            channel_status,
            channel_position,
            repeat = 0,
            goal_list
          )
        else
          robot = move(robot)
          %Task4CClientRobotA.Position{x: x, y: y, facing: facing} = robot

          # is_obs = Task4CClientRobotA.PhoenixSocketClient.send_robot_status(channel_status,channel_position,robot)
          correct_X(robot, goal_x, goal_y, channel_status, channel_position, goal_list)
        end

        %Task4CClientRobotA.Position{x: x, y: y, facing: facing} = robot
      else
        robot = move(robot)
        %Task4CClientRobotA.Position{x: x, y: y, facing: facing} = robot

        is_obs =
          Task4CClientRobotA.PhoenixSocketClient.send_robot_status(
            channel_status,
            channel_position,
            robot
          )

        robot = left(robot)

        is_obs =
          Task4CClientRobotA.PhoenixSocketClient.send_robot_status(
            channel_status,
            channel_position,
            robot
          )

        %Task4CClientRobotA.Position{x: x, y: y, facing: facing} = robot

        if is_obs do
          repeat = 1
          objInX_west(robot, goal_x, goal_y, channel_status, channel_position, repeat, goal_list)
        else
          robot = move(robot)

          # is_obs = Task4CClientRobotA.PhoenixSocketClient.send_robot_status(channel_status,channel_position,robot)
          %Task4CClientRobotA.Position{x: x, y: y, facing: facing} = robot
          go_to_goal(robot, goal_x, goal_y, channel_status, channel_position, goal_list)
        end

        %Task4CClientRobotA.Position{x: x, y: y, facing: facing} = robot
        # IO.puts("exited if")
      end
    else
      robot = left(robot)
      %Task4CClientRobotA.Position{x: x, y: y, facing: facing} = robot

      is_obs =
        Task4CClientRobotA.PhoenixSocketClient.send_robot_status(
          channel_status,
          channel_position,
          robot
        )

      if(is_obs) do
        robot = left(robot)
        %Task4CClientRobotA.Position{x: x, y: y, facing: facing} = robot

        is_obs =
          Task4CClientRobotA.PhoenixSocketClient.send_robot_status(
            channel_status,
            channel_position,
            robot
          )

        robot = move(robot)
        %Task4CClientRobotA.Position{x: x, y: y, facing: facing} = robot

        is_obs =
          Task4CClientRobotA.PhoenixSocketClient.send_robot_status(
            channel_status,
            channel_position,
            robot
          )

        robot = right(robot)
        %Task4CClientRobotA.Position{x: x, y: y, facing: facing} = robot

        is_obs =
          Task4CClientRobotA.PhoenixSocketClient.send_robot_status(
            channel_status,
            channel_position,
            robot
          )

        if(is_obs) do
          objInY_south(
            %Task4CClientRobotA.Position{x: x, y: y, facing: facing} = robot,
            goal_x,
            goal_y,
            channel_status,
            channel_position,
            repeat = 0,
            goal_list
          )
        else
          robot = move(robot)
          %Task4CClientRobotA.Position{x: x, y: y, facing: facing} = robot

          # is_obs = Task4CClientRobotA.PhoenixSocketClient.send_robot_status(channel_status,channel_position,robot)
          correct_X(robot, goal_x, goal_y, channel_status, channel_position, goal_list)
        end

        %Task4CClientRobotA.Position{x: x, y: y, facing: facing} = robot
      else
        robot = move(robot)
        %Task4CClientRobotA.Position{x: x, y: y, facing: facing} = robot

        is_obs =
          Task4CClientRobotA.PhoenixSocketClient.send_robot_status(
            channel_status,
            channel_position,
            robot
          )

        robot = right(robot)
        %Task4CClientRobotA.Position{x: x, y: y, facing: facing} = robot

        is_obs =
          Task4CClientRobotA.PhoenixSocketClient.send_robot_status(
            channel_status,
            channel_position,
            robot
          )

        if is_obs do
          repeat = 0
          objInX_west(robot, goal_x, goal_y, channel_status, channel_position, repeat, goal_list)
        else
          robot = move(robot)
          %Task4CClientRobotA.Position{x: x, y: y, facing: facing} = robot

          # is_obs = Task4CClientRobotA.PhoenixSocketClient.send_robot_status(channel_status,channel_position,robot)
          go_to_goal(robot, goal_x, goal_y, channel_status, channel_position, goal_list)
        end

        %Task4CClientRobotA.Position{x: x, y: y, facing: facing} = robot
        # IO.puts("exited else")
      end
    end

    %Task4CClientRobotA.Position{x: x, y: y, facing: facing} = robot
    # call the base go_to_goal func at this point
    # go_to_goal(robot, goal_x, goal_y, channel_status, channel_position,goal_list)
  end

  def objInX_east(
        %Task4CClientRobotA.Position{x: x, y: y, facing: facing} = robot,
        goal_x,
        goal_y,
        channel_status,
        channel_position,
        repeat,
        goal_list
      ) do
    # make sure bot is facing east before running this func
    # IO.puts("in east")

    %Task4CClientRobotA.Position{x: x, y: y, facing: facing} = robot

    # turn, move left and face west
    # turn, move right and face east//
    if y == :a or repeat == 1 do
      # boundry case
      # IO.puts("in y=a")
      robot = left(robot)
      %Task4CClientRobotA.Position{x: x, y: y, facing: facing} = robot

      is_obs =
        Task4CClientRobotA.PhoenixSocketClient.send_robot_status(
          channel_status,
          channel_position,
          robot
        )

      if(is_obs) do
        robot = left(robot)
        %Task4CClientRobotA.Position{x: x, y: y, facing: facing} = robot

        is_obs =
          Task4CClientRobotA.PhoenixSocketClient.send_robot_status(
            channel_status,
            channel_position,
            robot
          )

        robot = move(robot)
        %Task4CClientRobotA.Position{x: x, y: y, facing: facing} = robot

        is_obs =
          Task4CClientRobotA.PhoenixSocketClient.send_robot_status(
            channel_status,
            channel_position,
            robot
          )

        robot = right(robot)
        %Task4CClientRobotA.Position{x: x, y: y, facing: facing} = robot

        is_obs =
          Task4CClientRobotA.PhoenixSocketClient.send_robot_status(
            channel_status,
            channel_position,
            robot
          )

        if(is_obs) do
          objInY_north(
            %Task4CClientRobotA.Position{x: x, y: y, facing: facing} = robot,
            goal_x,
            goal_y,
            channel_status,
            channel_position,
            repeat = 0,
            goal_list
          )
        else
          robot = move(robot)
          %Task4CClientRobotA.Position{x: x, y: y, facing: facing} = robot

          # is_obs = Task4CClientRobotA.PhoenixSocketClient.send_robot_status(channel_status,channel_position,robot)
          correct_X(robot, goal_x, goal_y, channel_status, channel_position, goal_list)
        end

        %Task4CClientRobotA.Position{x: x, y: y, facing: facing} = robot
      else
        robot = move(robot)
        %Task4CClientRobotA.Position{x: x, y: y, facing: facing} = robot

        is_obs =
          Task4CClientRobotA.PhoenixSocketClient.send_robot_status(
            channel_status,
            channel_position,
            robot
          )

        robot = right(robot)
        %Task4CClientRobotA.Position{x: x, y: y, facing: facing} = robot

        is_obs =
          Task4CClientRobotA.PhoenixSocketClient.send_robot_status(
            channel_status,
            channel_position,
            robot
          )

        if is_obs do
          repeat = 1
          objInX_east(robot, goal_x, goal_y, channel_status, channel_position, repeat, goal_list)
        else
          robot = move(robot)
          %Task4CClientRobotA.Position{x: x, y: y, facing: facing} = robot
          go_to_goal(robot, goal_x, goal_y, channel_status, channel_position, goal_list)
        end

        %Task4CClientRobotA.Position{x: x, y: y, facing: facing} = robot

        # is_obs = Task4CClientRobotA.PhoenixSocketClient.send_robot_status(channel_status,channel_position,robot)
        # IO.puts("exited else")
      end
    else
      # IO.puts("in else")
      ##################
      robot = left(robot)
      %Task4CClientRobotA.Position{x: x, y: y, facing: facing} = robot

      is_obs =
        Task4CClientRobotA.PhoenixSocketClient.send_robot_status(
          channel_status,
          channel_position,
          robot
        )

      if(is_obs) do
        # IO.puts("in isobs")
        robot = right(robot)
        %Task4CClientRobotA.Position{x: x, y: y, facing: facing} = robot

        is_obs =
          Task4CClientRobotA.PhoenixSocketClient.send_robot_status(
            channel_status,
            channel_position,
            robot
          )

        robot = move(robot)
        %Task4CClientRobotA.Position{x: x, y: y, facing: facing} = robot

        is_obs =
          Task4CClientRobotA.PhoenixSocketClient.send_robot_status(
            channel_status,
            channel_position,
            robot
          )

        robot = left(robot)
        %Task4CClientRobotA.Position{x: x, y: y, facing: facing} = robot

        is_obs =
          Task4CClientRobotA.PhoenixSocketClient.send_robot_status(
            channel_status,
            channel_position,
            robot
          )

        if(is_obs) do
          objInY_south(
            %Task4CClientRobotA.Position{x: x, y: y, facing: facing} = robot,
            goal_x,
            goal_y,
            channel_status,
            channel_position,
            repeat = 0,
            goal_list
          )
        else
          robot = move(robot)
          %Task4CClientRobotA.Position{x: x, y: y, facing: facing} = robot

          # is_obs = Task4CClientRobotA.PhoenixSocketClient.send_robot_status(channel_status,channel_position,robot)
          correct_X(robot, goal_x, goal_y, channel_status, channel_position, goal_list)
        end

        %Task4CClientRobotA.Position{x: x, y: y, facing: facing} = robot
      else
        # IO.puts("in else isobs")
        robot = move(robot)
        %Task4CClientRobotA.Position{x: x, y: y, facing: facing} = robot

        is_obs =
          Task4CClientRobotA.PhoenixSocketClient.send_robot_status(
            channel_status,
            channel_position,
            robot
          )

        ###############
        robot = right(robot)

        is_obs =
          Task4CClientRobotA.PhoenixSocketClient.send_robot_status(
            channel_status,
            channel_position,
            robot
          )

        %Task4CClientRobotA.Position{x: x, y: y, facing: facing} = robot

        if is_obs do
          # IO.puts("in unwanted")
          repeat = 0
          objInX_east(robot, goal_x, goal_y, channel_status, channel_position, repeat, goal_list)
        else
          # IO.puts("in wanted")
          robot = move(robot)
          %Task4CClientRobotA.Position{x: x, y: y, facing: facing} = robot

          # is_obs = Task4CClientRobotA.PhoenixSocketClient.send_robot_status(channel_status,channel_position,robot)
          go_to_goal(robot, goal_x, goal_y, channel_status, channel_position, goal_list)
        end

        %Task4CClientRobotA.Position{x: x, y: y, facing: facing} = robot
        # IO.puts("exited if")
      end
    end

    %Task4CClientRobotA.Position{x: x, y: y, facing: facing} = robot
    # call the base go_to_goal func at this point
    # go_to_goal(robot, goal_x, goal_y, channel_status, channel_position,goal_list)
  end

  def go_to_goal(
        %Task4CClientRobotA.Position{x: x, y: y, facing: facing} = robot,
        goal_x,
        goal_y,
        channel_status,
        channel_position,
        goal_list
      ) do
    bool = check_if_goal_reached(goal_list, robot)

    if bool == true do
      is_obs =
        Task4CClientRobotA.PhoenixSocketClient.send_robot_status(
          channel_status,
          channel_position,
          robot
        )

      robot
    else
      is_obs =
        Task4CClientRobotA.PhoenixSocketClient.send_robot_status(
          channel_status,
          channel_position,
          robot
        )

      if y < goal_y do
        if facing != :north do
          robot =
            if facing == :east do
              robot = left(robot)
              %Task4CClientRobotA.Position{x: x, y: y, facing: facing} = robot
            else
              robot = right(robot)
              %Task4CClientRobotA.Position{x: x, y: y, facing: facing} = robot
            end

          %Task4CClientRobotA.Position{x: x, y: y, facing: facing} = robot
          go_to_goal(robot, goal_x, goal_y, channel_status, channel_position, goal_list)
        else
          if(is_obs) do
            objInY_north(
              robot,
              goal_x,
              goal_y,
              channel_status,
              channel_position,
              repeat = 0,
              goal_list
            )
          else
            robot = move(robot)
            IO.inspect(robot)
            go_to_goal(robot, goal_x, goal_y, channel_status, channel_position, goal_list)
          end
        end
      else
        if y > goal_y do
          if facing != :south do
            robot =
              if facing == :west do
                robot = left(robot)
                %Task4CClientRobotA.Position{x: x, y: y, facing: facing} = robot
              else
                robot = right(robot)
                %Task4CClientRobotA.Position{x: x, y: y, facing: facing} = robot
                robot = right_turn(robot)
                %Task4CClientRobotA.Position{x: x, y: y, facing: facing} = robot
              end

            go_to_goal(robot, goal_x, goal_y, channel_status, channel_position, goal_list)
          else
            if(is_obs) do
              objInY_south(
                robot,
                goal_x,
                goal_y,
                channel_status,
                channel_position,
                repeat = 0,
                goal_list
              )
            else
              robot = move(robot)
              go_to_goal(robot, goal_x, goal_y, channel_status, channel_position, goal_list)
            end
          end
        else
          if x > goal_x do
            if facing != :west do
              robot =
                if facing == :north do
                  robot = left(robot)
                  %Task4CClientRobotA.Position{x: x, y: y, facing: facing} = robot
                else
                  robot = right(robot)
                  %Task4CClientRobotA.Position{x: x, y: y, facing: facing} = robot
                end

              %Task4CClientRobotA.Position{x: x, y: y, facing: facing} = robot
              go_to_goal(robot, goal_x, goal_y, channel_status, channel_position, goal_list)
            else
              if(is_obs) do
                objInX_west(
                  robot,
                  goal_x,
                  goal_y,
                  channel_status,
                  channel_position,
                  repeat = 0,
                  goal_list
                )
              else
                robot = move(robot)
                go_to_goal(robot, goal_x, goal_y, channel_status, channel_position, goal_list)
              end
            end
          else
            if x < goal_x do
              if facing != :east do
                robot =
                  if facing == :south do
                    robot = left(robot)
                    %Task4CClientRobotA.Position{x: x, y: y, facing: facing} = robot
                  else
                    robot = right(robot)
                    %Task4CClientRobotA.Position{x: x, y: y, facing: facing} = robot
                  end

                %Task4CClientRobotA.Position{x: x, y: y, facing: facing} = robot
                go_to_goal(robot, goal_x, goal_y, channel_status, channel_position, goal_list)
              else
                if(is_obs) do
                  objInX_east(
                    robot,
                    goal_x,
                    goal_y,
                    channel_status,
                    channel_position,
                    repeat = 0,
                    goal_list
                  )
                else
                  robot = move(robot)
                  go_to_goal(robot, goal_x, goal_y, channel_status, channel_position, goal_list)
                end
              end
            else
              Task4CClientRobotA.PhoenixSocketClient.send_robot_status(
                channel_status,
                channel_position,
                robot
              )
            end
          end
        end
      end
    end
  end

  #############################################################################################################################
  ############################################## Algorithm ####################################################################
  #############################################################################################################################

  ##############################################################################################################################
  ############################################# Linefollowing ##################################################################
  ##############################################################################################################################
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

  def start_follow(
        error,
        prev_error,
        difference,
        cumulative_error,
        correction,
        node_cnt,
        black_cnt
      ) do
    readings = get_sensor_readings()
    k = readings.og
    newk = readings.bin
    error = calc_err(k, newk, error, prev_error)
    error = 10 * error
    difference = error - prev_error
    cumulative_error = cumulative_error + error

    cumulative_error =
      if cumulative_error > 30 do
        30
      else
        if cumulative_error < -30 do
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
      else
        if left_duty_cycle > @caphigh do
          @caphigh
        else
          left_duty_cycle
        end
      end

    right_duty_cycle = @right_const + correction

    right_duty_cycle =
      if right_duty_cycle < @caplow do
        @caplow
      else
        if right_duty_cycle > @caphigh do
          @caphigh
        else
          right_duty_cycle
        end
      end

    black_cnt =
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
      if black_cnt > 10 do
        stop()
        black_cnt
      else
        if newk == [1, 1, 1, 1, 1] do
          stop()
          black_cnt
        else
          if Enum.count(newk, &(&1 > 0)) >= 3 do
            IO.inspect(newk)
            IO.puts("node")
            Process.sleep(10)
            stop()
            Process.sleep(1000)
            black_cnt
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

    if Enum.count(newk, &(&1 > 0)) <= 2 do
      start_follow(
        error,
        prev_error,
        difference,
        cumulative_error,
        correction,
        node_cnt,
        black_cnt
      )
    end
  end

  def get_sensor_readings do
    # Logger.debug("Testing white line sensors connected ")
    sensor_ref = Enum.map(@sensor_pins, fn {atom, pin_no} -> configure_sensor({atom, pin_no}) end)
    sensor_ref = Enum.map(sensor_ref, fn {_atom, ref_id} -> ref_id end)
    sensor_ref = Enum.zip(@ref_atoms, sensor_ref)

    error = 0.0
    prev_error = 0.0
    difference = 0.0
    cumulative_error = 0.0
    correction = 0.0
    node_cnt = 0
    black_cnt = 0

    get_lfa_readings(
      [0, 1, 2, 3, 4],
      sensor_ref,
      error,
      prev_error,
      difference,
      cumulative_error,
      correction,
      node_cnt,
      black_cnt
    )
  end

  defp configure_sensor({atom, pin_no}) do
    if atom == :dataout do
      GPIO.open(pin_no, :input, pull_mode: :pullup)
    else
      GPIO.open(pin_no, :output)
    end
  end

  defp motor_new(motor_ref, motion) do
    motor_ref
    |> Enum.zip(motion)
    |> Enum.each(fn {{_, ref_no}, value} -> GPIO.write(ref_no, value) end)

    Process.sleep(1000)
  end

  defp motor_action(motor_ref, motion) do
    motor_ref
    |> Enum.zip(motion)
    |> Enum.each(fn {{_, ref_no}, value} -> GPIO.write(ref_no, value) end)
  end

  # to stop the robot
  def stop() do
    Process.sleep(200)
    motor_ref = Enum.map(@motor_pins, fn {_atom, pin_no} -> GPIO.open(pin_no, :output) end)
    pwm_ref = Enum.map(@pwm_pins, fn {_atom, pin_no} -> GPIO.open(pin_no, :output) end)
    Enum.map(pwm_ref, fn {_, ref_no} -> GPIO.write(ref_no, 1) end)
    motion_list = [@stop]
    Enum.each(motion_list, fn motion -> motor_new(motor_ref, motion) end)
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

  defp get_lfa_readings(
         sensor_list,
         sensor_ref,
         error,
         prev_error,
         difference,
         cumulative_error,
         correction,
         node_cnt,
         black_cnt
       ) do
    append_sensor_list = sensor_list ++ [5]
    temp_sensor_list = [5 | append_sensor_list]

    k =
      append_sensor_list
      |> Enum.with_index()
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

    weighted_sum =
      -3.0 * Enum.at(k, 0) + -1.0 * Enum.at(k, 1) + 0 * Enum.at(k, 2) + 1.0 * Enum.at(k, 3) +
        3.0 * Enum.at(k, 4)

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
    if counter == 0 do
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
    if n < 4 do
      if (sens_num >>> (3 - n) &&& 0x01) == 1 do
        GPIO.write(sensor_ref[:address], 1)
      else
        GPIO.write(sensor_ref[:address], 0)
      end

      Process.sleep(1)
    end

    %{^sensor_atom_num => sensor_atom} = @lf_sensor_map

    if n <= 9 do
      Map.update!(acc, sensor_atom, fn sensor_atom ->
        sensor_atom <<< 1 ||| GPIO.read(sensor_ref[:dataout])
      end)
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
    Process.sleep(500)
  end

  defp pwm(duty) do
    Enum.each(@pwm_pins, fn {_atom, pin_no} -> Pigpiox.Pwm.gpio_pwm(pin_no, duty) end)
  end
  ##############################################################################################################################
  ############################################# Linefollowing ##################################################################
  ##############################################################################################################################

  ##############################################################################################################################
  ############################################# Robot Movement #################################################################
  ##############################################################################################################################
  # Places the robot to the default position of (1, A, North)
  def place do
    {:ok, %Task4CClientRobotA.Position{}}
  end
  def place(x, y, _facing) when x < 1 or y < :a or x > @table_top_x or y > @table_top_y do
    {:failure, "Invalid position"}
  end
  def place(_x, _y, facing) when facing not in [:north, :east, :south, :west] do
    {:failure, "Invalid facing direction"}
  end
  # Places the robot to the provided position of (x, y, facing),
  # but prevents it to be placed outside of the table and facing invalid direction.
  def place(x, y, facing) do
    {:ok, %Task4CClientRobotA.Position{x: x, y: y, facing: facing}}
  end
  def report(%Task4CClientRobotA.Position{x: x, y: y, facing: facing} = _robot) do
    {x, y, facing}
  end

  @directions_to_the_right %{north: :east, east: :south, south: :west, west: :north}
  def start(x, y, facing) do
    place(x, y, facing)
  end
  def align(channel_position) do
    do_seeding("left", channel_position)
    do_seeding("right", channel_position)
  end
  def do_seeding(side, channel_position) do
    # write the code to rotate the servo and perform seeding
    if(side == "left") do
      test_servo_a(60)
      update_seeding_status(side, channel_position)
    else
      test_servo_b(60)
      update_seeding_status(side, channel_position)
    end
  end
  def test_servo_a(angle) do
    Logger.debug("Testing Servo A")
    val = trunc((2.5 + 10.0 * angle / 180) / 100 * 255)
    Pigpiox.Pwm.set_pwm_frequency(@servo_a_pin, @pwm_frequency)
    Pigpiox.Pwm.gpio_pwm(@servo_a_pin, val)
  end
  def initialize_servo do
    test_servo_a(0)
    test_servo_b(0)
  end
  def test_servo_b(angle) do
    Logger.debug("Testing Servo B")
    val = trunc((2.5 + 10.0 * angle / 180) / 100 * 255)
    Pigpiox.Pwm.set_pwm_frequency(@servo_b_pin, @pwm_frequency)
    Pigpiox.Pwm.gpio_pwm(@servo_b_pin, val)
  end
  def follow_line_until do
    error = 0.0
    prev_error = 0.0
    difference = 0.0
    cumulative_error = 0.0
    correction = 0.0
    node_cnt = 0
    black_cnt = 0

    start_follow_until(
      error,
      prev_error,
      difference,
      cumulative_error,
      correction,
      node_cnt,
      black_cnt
    )
  end

  def drop_seed do
    Process.sleep(1000)
    # IO.puts("seeded")
    test_servo_a(60)
    ###### function add kar
  end

  def start_follow_until(
        error,
        prev_error,
        difference,
        cumulative_error,
        correction,
        node_cnt,
        black_cnt
      ) do
    readings = get_sensor_readings()
    k = readings.og
    newk = readings.bin
    is_plant = get_ir
    #  IO.inspect(k)
    #  IO.inspect(newk)
    is_plant_new = get_ir_new

    error = calc_err(k, newk, error, prev_error)
    error = 10 * error
    difference = error - prev_error
    cumulative_error = cumulative_error + error

    cumulative_error =
      if cumulative_error > 30 do
        30
      else
        if cumulative_error < -30 do
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
      else
        if left_duty_cycle > @caphigh do
          @caphigh
        else
          left_duty_cycle
        end
      end

    right_duty_cycle = @right_const + correction

    right_duty_cycle =
      if right_duty_cycle < @caplow do
        @caplow
      else
        if right_duty_cycle > @caphigh do
          @caphigh
        else
          right_duty_cycle
        end
      end

    #  IO.inspect("#{newk}")
    black_cnt =
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
      if black_cnt > 10 do
        stop()
        black_cnt
      else
        if newk == [1, 1, 1, 1, 1] do
          stop()
          black_cnt
        else
          if is_plant_new == true do
            stop_new()
            drop_seed_new()

            start_follow(
              error,
              prev_error,
              difference,
              cumulative_error,
              correction,
              node_cnt,
              black_cnt
            )

            black_cnt
          else
            if is_plant == true do
              stop_new()
              drop_seed()

              start_follow(
                error,
                prev_error,
                difference,
                cumulative_error,
                correction,
                node_cnt,
                black_cnt
              )

              black_cnt
              #  else if (Enum.count(newk, &(&1 > 0)) >= 3) do
              #   IO.inspect(newk)
              #   IO.puts("node")
              #   black_cnt
              #   stop()
              #   Process.sleep(1000)
            else
              # IO.puts("left #{left_duty_cycle}")
              # IO.puts("right #{right_duty_cycle}")

              # if(node_cnt < 4) do
              move(left_duty_cycle, right_duty_cycle)
              # else
              # stop()
            end

            black_cnt
          end
        end
      end
  end
  def drop_seed_new do
    Process.sleep(1000)
    IO.puts("new seeding")
    test_servo_b(60)
    ###### function add kar
  end
  def get_ir do
    # Logger.debug("Testing IR Proximity Sensors")
    ir_ref =
      Enum.map(@ir_pins, fn {_atom, pin_no} -> GPIO.open(pin_no, :input, pull_mode: :pullup) end)

    ir_values = Enum.map(ir_ref, fn {_, ref_no} -> GPIO.read(ref_no) end)

    if ir_values == [0, 1] do
      true
    else
      false
    end

    # if (ir_values == [1, 0]) do
    #   true
    # else
    #   false
    # end
  end
  def get_ir_new do
    # Logger.debug("Testing IR Proximity Sensors")
    ir_ref =
      Enum.map(@ir_pins, fn {_atom, pin_no} -> GPIO.open(pin_no, :input, pull_mode: :pullup) end)

    ir_values = Enum.map(ir_ref, fn {_, ref_no} -> GPIO.read(ref_no) end)
    # if (ir_values == [0, 1]) do
    #   true
    # else
    #   false
    # end

    if ir_values == [1, 0] do
      true
    else
      false
    end
  end
  def stop_new do
    motor_ref = Enum.map(@motor_pins, fn {_atom, pin_no} -> GPIO.open(pin_no, :output) end)
    pwm_ref = Enum.map(@pwm_pins, fn {_atom, pin_no} -> GPIO.open(pin_no, :output) end)
    Enum.map(pwm_ref, fn {_, ref_no} -> GPIO.write(ref_no, 1) end)
    motion_list = [@stop]
    Enum.each(motion_list, fn motion -> motor_new(motor_ref, motion) end)
  end
  @directions_to_the_right %{north: :east, east: :south, south: :west, west: :north}
  def right(%Task4CClientRobotA.Position{facing: facing} = robot) do
    stop()
    Process.sleep(1000)
    motor_ref = Enum.map(@new_motor_pins, fn {_atom, pin_no} -> GPIO.open(pin_no, :output) end)
    motor_action(motor_ref, @only_right)
    Enum.map(@duty_cycles, fn value -> motion_pwm_right(value) end)
    # motor_ref = Enum.map(@new_motor_pins, fn {_atom, pin_no} -> GPIO.open(pin_no, :output) end)
    # motor_action(motor_ref, @only_right)
    # Enum.map(@duty_cycles, fn value -> motion_pwm_right(value) end)
    %Task4CClientRobotA.Position{robot | facing: @directions_to_the_right[facing]}
  end
  def right_turn(%Task4CClientRobotA.Position{facing: facing} = robot) do
    # stop()
    Process.sleep(1000)
    motor_ref = Enum.map(@new_motor_pins, fn {_atom, pin_no} -> GPIO.open(pin_no, :output) end)
    motor_action(motor_ref, @only_right)
    Enum.map(@duty_cycles, fn value -> motion_pwm_right_turn(value) end)
    # motor_ref = Enum.map(@new_motor_pins, fn {_atom, pin_no} -> GPIO.open(pin_no, :output) end)
    # motor_action(motor_ref, @only_right)
    # Enum.map(@duty_cycles, fn value -> motion_pwm_right(value) end)
    %Task4CClientRobotA.Position{robot | facing: @directions_to_the_right[facing]}
  end
  defp motion_pwm_right_turn(value) do
    pwm(value)
    Process.sleep(550)
  end
  defp motion_pwm_right(value) do
    pwm(value)
    Process.sleep(450)
  end
  defp motion_pwm_left(value) do
    pwm(value)
    Process.sleep(440)
  end
  @directions_to_the_left Enum.map(@directions_to_the_right, fn {from, to} -> {to, from} end)

  def left(%Task4CClientRobotA.Position{facing: facing} = robot) do
    stop()
    Process.sleep(1000)
    motor_ref = Enum.map(@motor_pins, fn {_atom, pin_no} -> GPIO.open(pin_no, :output) end)
    motor_action(motor_ref, @left)
    Enum.map(@duty_cycles, fn value -> motion_pwm_left(value) end)
    %Task4CClientRobotA.Position{robot | facing: @directions_to_the_left[facing]}
  end


  def move(%Task4CClientRobotA.Position{x: _, y: y, facing: :north} = robot)
      when y < @table_top_y do
    %Task4CClientRobotA.Position{
      robot
      | y:
          Enum.find(@robot_map_y_atom_to_num, fn {_, val} ->
            val == Map.get(@robot_map_y_atom_to_num, y) + 1
          end)
          |> elem(0)
    }
    follow_line()
    %Task4CClientRobotA.Position{robot | y: Enum.find(@robot_map_y_atom_to_num, fn {_, val} -> val == Map.get(@robot_map_y_atom_to_num, y) + 1 end) |> elem(0)}
  end

  def move(%Task4CClientRobotA.Position{x: x, y: _, facing: :east} = robot)
    when x < @table_top_x do
    follow_line()
    %Task4CClientRobotA.Position{robot | x: x + 1}
  end

  def move(%Task4CClientRobotA.Position{x: _, y: y, facing: :south} = robot) when y > :a do
    %Task4CClientRobotA.Position{
      robot
      | y:
          Enum.find(@robot_map_y_atom_to_num, fn {_, val} ->
            val == Map.get(@robot_map_y_atom_to_num, y) - 1
          end)
          |> elem(0)
    }
    follow_line()
    %Task4CClientRobotA.Position{robot | y: Enum.find(@robot_map_y_atom_to_num, fn {_, val} -> val == Map.get(@robot_map_y_atom_to_num, y) - 1 end) |> elem(0)}
  end

  def move(%Task4CClientRobotA.Position{x: x, y: _, facing: :west} = robot) when x > 1 do
    follow_line()
    %Task4CClientRobotA.Position{robot | x: x - 1}
  end
  def move(robot), do: robot
  def failure do
    raise "Connection has been lost"
  end
  ##############################################################################################################################
  ############################################# Robot Movement #################################################################
  ##############################################################################################################################


  ##############################################################################################################################
  ############################################# Communication ##################################################################
  ##############################################################################################################################
  def main do
    initialize_servo()
    {:ok, _response, channel_status, channel_position} =
      Task4CClientRobotA.PhoenixSocketClient.connect_server()
    {:ok, position} = get_start_pos(channel_position)
    new = String.replace(position, " ", "")
    str = String.split(new, ",")
    {x, ""} = Integer.parse(Enum.at(str, 0))
    y = String.to_atom(Enum.at(str, 1))
    facing = String.to_atom(Enum.at(str, 2))
    robot_start = %Task4CClientRobotA.Position{x: x, y: y, facing: facing}
    start(x, y, facing)
    {:ok, goal_locs} = get_goal_locs(channel_position)
    {:ok, goal_locs_cell} = get_goal_locs_cell(channel_position)
    IO.inspect(goal_locs_cell)
    list_ret = []
    goalssssss = make_goal_list_for_cells(goal_locs_cell, list_ret)
    count = 1
    goal_locs = stop(robot_start, goal_locs, channel_status, channel_position, goalssssss, count)
    Process.sleep(5000)
    broadcast_stop(channel_position)
    rob = get_correct_robot_position(channel_position)
  end

  def check_if_goal_reached(goal_list, robot) do
    x = Integer.to_string(robot.x)
    y = Atom.to_string(robot.y)
    goal = [x, y]
    bool = Enum.member?(goal_list, goal)
  end

  def make_goal_list_for_cells(goal_locs_cell, list_ret) do
    if Enum.empty?(goal_locs_cell) == true do
      list_ret
    else
      n = Enum.at(goal_locs_cell, 0)
      list = get_goal(n)
      list_ret = list_ret ++ [list]
      goal_locs_cell = List.delete_at(goal_locs_cell, 0)
      make_goal_list_for_cells(goal_locs_cell, list_ret)
    end
  end

  def get_goal(n) do
    map = %{1 => "a", 2 => "b", 3 => "c", 4 => "d", 5 => "e", 6 => "f"}
    n = String.to_integer(n)

    list =
      cond do
        n >= 1 and n <= 5 ->
          x1 = to_string(n)
          x2 = to_string(n + 1)
          y1 = map[1]
          y2 = map[2]
          lst = [[x1, y1], [x1, y2], [x2, y1], [x2, y2]]

        # lst = [x1, y1]

        n >= 6 and n <= 10 ->
          x1 = to_string(n - 5)
          x2 = to_string(n - 5 + 1)
          y1 = map[2]
          y2 = map[3]
          # lst = [x1,y1,x1,y2,x2,y1,x2,y2]
          lst = [[x1, y1], [x1, y2], [x2, y1], [x2, y2]]

        # lst = [x1, y1]

        n >= 11 and n <= 15 ->
          x1 = to_string(n - 10)
          x2 = to_string(n - 10 + 1)
          y1 = map[3]
          y2 = map[4]
          # lst = [x1,y1,x1,y2,x2,y1,x2,y2]
          lst = [[x1, y1], [x1, y2], [x2, y1], [x2, y2]]

        # lst = [x1, y1]

        n >= 16 and n <= 20 ->
          x1 = to_string(n - 15)
          x2 = to_string(n - 15 + 1)
          y1 = map[4]
          y2 = map[5]
          # lst = [x1, y1]
          lst = [[x1, y1], [x1, y2], [x2, y1], [x2, y2]]

        # lst = [x1,y1,x1,y2,x2,y1,x2,y2]
        n >= 21 and n <= 25 ->
          x1 = to_string(n - 20)
          x2 = to_string(n - 20 + 1)
          y1 = map[5]
          y2 = map[6]
          # lst = [x1,y1,x1,y2,x2,y1,x2,y2]
          # lst = [x1, y1]
          lst = [[x1, y1], [x1, y2], [x2, y1], [x2, y2]]
      end

    list
  end

  def get_goal_locs_cell(channel) do
    {:ok, goal_locs} = PhoenixClient.Channel.push(channel, "give_goal_loc_a_cell", "nil")

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

  def broadcast_stop(channel_position) do
    {:ok, reply} = PhoenixClient.Channel.push(channel_position, "stop_a", "nil")
  end

  # fucntio to get the start positions entered by the user on the server arena live
  def get_start_pos(channel) do
    {:ok, position} = PhoenixClient.Channel.push(channel, "give_start_posa", "nil")

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
    {:ok, goal_locs} = PhoenixClient.Channel.push(channel, "give_goal_loc_a", "nil")

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

  def send_goal_loc(channel_position, goal_location) do
    {:ok, reply} =
      PhoenixClient.Channel.push(channel_position, "incoming_goal_loc_a", goal_location)
  end
  def update_seeding_status(side, channel_position) do
    {:ok, data} = PhoenixClient.Channel.push(channel_position, "update_dispenser_status", side)
  end

  def get_dispenser_status(channel_position) do
    {ok, map} = PhoenixClient.Channel.push(channel_position, "give_dispenser_status", "nil")
    {map["left"], map["right"]}
  end
  def get_correct_robot_position(channel_position) do
    {:ok, robot_position} = PhoenixClient.Channel.push(channel_position, "give_roba_pos", "nil")
    robot_position
  end
  #the function to cover all the ogal location one by one
  def stop(robot, goal_locs, channel_status, channel_position, goalss, count) do
    goal_locs =
      if Enum.empty?(goal_locs) == false do
        goal1 = Enum.at(goal_locs, 0)
        goal_list = Enum.at(goalss, 0)
        goal_x = String.to_integer(Enum.at(goal1, 0))
        goal_y = String.to_atom(Enum.at(goal1, 1))
        robot_old = go_to_goal(robot, goal_x, goal_y, channel_status, channel_position, goal_list)
        # robot_final_test = line_follow_and_communication_test(robot,goal_x,goal_y,channel_status,channel_position)
        if count == 1 do
          test_servo_a(60)
        end

        if count == 2 do
          test_servo_a(120)
        end

        if count == 3 do
          test_servo_a(180)
        end

        if count == 4 do
          test_servo_b(60)
        end

        robot_corr = get_correct_robot_position(channel_position)
        count = count + 1

        #########################################################################################################
        ################## write code to update the seeding done event after seeding is done ####################
        #########################################################################################################
        # align(channel_position)
        {left, right} = get_dispenser_status(channel_position)
        goal_locs = List.delete_at(goal_locs, 0)
        goalss = List.delete_at(goalss, 0)
        robot = %Task4CClientRobotA.Position{
          x: robot_corr["x"],
          y: String.to_atom(robot_corr["y"]),
          facing: String.to_atom(robot_corr["face"])
        }
        stop(robot, goal_locs, channel_status, channel_position, goalss, count)
      else
        goal_locs
      end

    goal_locs
  end

  ##############################################################################################################################
  ############################################# Communication ##################################################################
  ##############################################################################################################################


  ##############################################################################################################################
  ############################################# tests ##########################################################################
  ##############################################################################################################################
  def line_follow_and_communication_test(robot, goal_x, goal_y, channel_status, channel_position) do
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
    test_servo_b(60)
    # robot = left(robot)
    # is_obs =
    #   Task4CClientRobotA.PhoenixSocketClient.send_robot_status(
    #     channel_status,
    #     channel_position,
    #     robot
    #   )
    # robot = right_turn(robot)
    # is_obs =
    #   Task4CClientRobotA.PhoenixSocketClient.send_robot_status(
    #     channel_status,
    #     channel_position,
    #     robot
    #   )
    robot
  end
  ##############################################################################################################################
  ############################################# tests ##########################################################################
  ##############################################################################################################################
end
