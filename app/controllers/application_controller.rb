class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  # protect_from_forgery with: :exception
  @@const = OpenStruct.new({
    :position => 1.0, # Constant for scaling position difference
    :rotation => 1.0, # Constant for scaling rotation difference
    :mixratio => 0.5, # Blending position & rotation scores in [0, 1]. 1 for position-only, 0 for rotation-only
    :update_damp => 0.8, # Updating Damping factor in [0, 1]. 0 for not update, 1 for applying entire difference
  })

  ## Alias functions for episode data update ##
  def states_to_commands(states, timestep)
    diff_states = objectify_json(states_to_diff_states(refine_states(states), timestep).to_json)
    commands = objectify_json(diff_states_to_commands(diff_states).to_json)
  end

  ## Episode Data Manipulation ##
  # Temporarily ignores ry, rz to zero
  def control_points_to_states(control_points, timestep)
    bez = Bezier::Curve.new(*control_points.map{ |point| [point["x"], point["y"], point["z"], point["rz"]]})
    max_time = control_points.last["t"]
    states = []
    time = 0
    while time <= max_time do
      point = bez.point_on_curve(time / max_time)
      states.push({
        :t => time,
        :x => point.x,
        :y => point.y,
        :z => point.z,
        :rx => 0.0,
        :ry => 0.0,
        :rz => point.r,
      })
      time += timestep
    end
    states
  end

  def states_to_diff_states(states, timestep)
    (0...states.length-1).map do |i|
      curr_state, next_state, timestep_in_sec = states[i], states[i+1], timestep / 1000.0

      curr_pos, curr_rot = state_to_position_and_rotation(curr_state)
      next_pos, next_rot = state_to_position_and_rotation(next_state)

      local_velocity = curr_rot.inverse * (next_pos - curr_pos) / timestep_in_sec
      rotation_diff = curr_rot.inverse * next_rot
      global_x_axis = Geo3d::Vector.new 1, 0, 0
      diff_x_axis = rotation_diff * global_x_axis
      rz_diff = Math.acos(diff_x_axis.normalize.dot global_x_axis)
      rz_diff = -rz_diff if diff_x_axis.y < 0

      {
        :t   => curr_state["t"],
        :dx  => clip(local_velocity.x, 15.0), # Will be converted into Roll in client
        :dy  => clip(local_velocity.y, 15.0), # Will be converted into Pitch in client
        :dz  => clip(local_velocity.z,  4.0), # Will be converted into Throttle in client
        :drz => clip(rz_diff.to_degrees / timestep_in_sec, 100.0), # Will be converted into Yaw in client
      }
    end
  end

  def diff_states_to_commands(diff_states)
    diff_states.map do |diff_state|
      {
        :t   => diff_state["t"],
        :dx  => normalized_clip(diff_state["dx"],   15.0), # Will be converted into Roll in client
        :dy  => normalized_clip(diff_state["dy"],   15.0), # Will be converted into Pitch in client
        :dz  => normalized_clip(diff_state["dz"],    4.0), # Will be converted into Throttle in client
        :drz => normalized_clip(diff_state["drz"], 100.0), # Will be converted into Yaw in client
      }
    end
  end

  # States Refinements
  def refine_states(states)
    bias_pos, _ = state_to_position_and_rotation(states[0])
    bias_mat = Geo3d::Matrix.rotation_z states[0]["rz"].degrees
    states.map do |state|
      pos, mat = state_to_position_and_rotation(state)
      refined_pos = bias_mat.inverse * (pos - bias_pos)
      refined_mat = bias_mat.inverse * mat
      state_from_position_and_rotation state["t"], refined_pos, refined_mat
    end
  end

  ## Matrix Calculation Helpers ##
  def state_from_position_and_rotation(t, position, rotation)
    rx, ry, rz = matrix_to_euler(rotation)
    {
      "t" => t,
      "x" => position.x,
      "y" => position.y,
      "z" => position.z,
      "rx" => rx,
      "ry" => ry,
      "rz" => rz,
    }
  end

  def state_to_position_and_rotation(state)
    pos = Geo3d::Vector.new state["x"], state["y"], state["z"]
    rot = Geo3d::Matrix.identity
    rot *= Geo3d::Matrix.rotation_x state["rx"].degrees
    rot *= Geo3d::Matrix.rotation_y state["ry"].degrees
    rot *= Geo3d::Matrix.rotation_z state["rz"].degrees
    return pos, rot
  end

  def matrix_to_euler(matrix)
    quaternion = matrix_to_quaternion matrix
    x, y, z, w = quaternion.x, quaternion.y, quaternion.z, quaternion.w
    rx = Math::atan( (2 * (w * x + y * z)) / (w**2 - x**2 - y**2 + z**2) )
    ry = Math::asin( -2 * (x*z - w*y) )
    rz = Math::atan( (2 * (x*y + w*z)) / (w**2 + x**2 - y**2 - z**2) )
    return rx.to_degrees, ry.to_degrees, rz.to_degrees
  end

  def matrix_to_quaternion (m)
    q = [0, 0, 0, 0]
    next_index = [1, 2, 0]

    trace = m[0,0] + m[1,1] + m[2,2]
    if trace > 0.0
      s = Math.sqrt( trace + 1.0 )
      q[0] = ( s * 0.5 )
      s = 0.5 / s
      q[1] = ( m[1,2] - m[2,1] ) * s
      q[2] = ( m[2,0] - m[0,2] ) * s
      q[3] = ( m[0,1] - m[1,0] ) * s
    else
      i = 0
      i = 1 if m[1,1] > m[0,0]
      i = 2 if m[2,2] > m[i,i]

      j = next_index[i]
      k = next_index[j]

      s = Math.sqrt( (m[i,i] - (m[j,j] + m[k,k])) + 1.0 )
      q[i+1] = s * 0.5
      s = 0.5 / s
      q[0]   = ( m[j,k] - m[k,j] ) * s
      q[j+1] = ( m[i,j] + m[j,i] ) * s
      q[k+1] = ( m[i,k] + m[k,i] ) * s
    end
    Geo3d::Quaternion.new q[1], q[2], q[3], q[0]
  end

  ## Simple Math ##
  ## Limitations of Drone (both positive & negative)
  # Yaw : 100degrees/s
  # Pitch Roll : 15m/s
  # Throttle : 4m/s
  def clip(value, limit, offset = 0)
    clipped_val = value
    clipped_val = offset + limit if value > offset + limit
    clipped_val = offset - limit if value < offset - limit
    clipped_val
  end

  def clipped?(value, limit, offset = 0)
    value == clip(value, limit, offset)
  end

  def normalized_clip(value, limit)
    clip(value, limit) / limit
  end

  ## Objectify : Decode into Ruby Object ##
  def objectify_episode (episode)
    {
      :id             => episode.id,
      :name           => episode.name,
      :timestep       => episode.timestep,
      :states         => objectify_json(episode.states),
      :diff_states    => objectify_json(episode.diff_states),
      :commands       => objectify_json(episode.commands),
      :simulator_logs => objectify_json(episode.simulator_logs),
      :created_at     => episode.created_at,
      :updated_at     => episode.updated_at,
    }
  end

  def objectify_optimization (optimization)
    {
      :episode                  => objectify_episode(optimization.episode),
      :states_list              => objectify_json(optimization.states_list),
      :commands_list            => objectify_json(optimization.commands_list),
      :simulator_log_list       => objectify_json(optimization.simulator_log_list),
      :max_iteration_count      => optimization.max_iteration_count,
      :current_iteration_index  => optimization.current_iteration_index,
      :created_at               => optimization.created_at,
      :updated_at               => optimization.updated_at,
    }
  end

  def objectify_optimization_to_feedback_form(optimization)
    current, max = optimization.current_iteration_index, optimization.max_iteration_count
    {
      :id => optimization.id,
      :current_iteration_index => current,
      :timestep => optimization.episode.timestep,
      :commands => current >= max ? [] : objectify_json(optimization.commands_list)[current], # Empty Commands considered as termination
      :success => true, # TODO : implement this
      :error_message => "Error Message!!" # TODO : implement this
    }
  end

  def objectify_json(json_string)
    JSON.parse(json_string) #, object_class: OpenStruct)
  end
end
