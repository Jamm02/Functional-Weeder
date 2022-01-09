defmodule LF do
  @moduledoc """
  Documentation for `LF`.
  """

  @doc """
  Hello world.

  ## Examples

      iex> LF.hello()
      :world

  """
  def set_values do
    error = 0
    prev_error=0
    kp=0
    kd=0
    ki=0
    # Also define weights
  end


  def calculate_error() do
    all_black_flag = 1; # assuming initially all black condition
    weighted_sum = 0
    sum = 0;
    pos = 0;

    # Step-1 :Loop to calculate pos i.e error

    # step -2 : condition to handle an al black flag situation
    if all_black_flag == 1 do
      if prev_error > 0 do # If previos error is positive then sets current error to max positive value
        error = 2.5;
      else               # If previos error is negative then sets current error to max negative value
        error = -2.5
      end
    else                # If no all black flag condition
      error = pos
    end
  end

  def  calculate_correction()do
    # error = error*10;  // we need the error correction in range 0-100 so that we can send it directly as duty cycle paramete

    # Step-1 : Find correct range of found error for Kp

    # Step-2: Find difference between previous error and current error for Kd
    difference = error - prev_error

    #  Step -3 : Find cumulative error for Ki
    cumulative_error += error


    # Step -4 : Find correct range of cumulative error
    # cumulative_error = bound(cumulative_error, -30, 30);

    # Step -5 : calculate correction using predefined k values
    correction = kp*error + ki*cumulative_error + kd*difference;
    prev_error = error;

  end

  def main do
    # Inside infinite loop
    # step 1 : read sensor values
    # step - Calculate correction
    calculate_error()
    calculate_correction()

    # Step - 3: Based on calculated corrections make changes to robot direction


  end



end
