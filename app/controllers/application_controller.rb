class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  # protect_from_forgery with: :exception

  ## Alias functions for episode data update ##
  def states_to_commands(states, timestep)
    diff_states = JSON.parse(states_to_diff_states(states, timestep).to_json)
    commands = JSON.parse(diff_states_to_commands(diff_states).to_json)
  end

  ## Episode Data Manipulation ##
  def states_to_diff_states(states, timestep)
    (0...states.length-1).map do |i|
      curr_state, next_state, timestep_in_sec = states[i], states[i+1], timestep / 1000.0

      curr_pos = Geo3d::Vector.new curr_state["x"], curr_state["y"], curr_state["z"]
      curr_mat = Geo3d::Matrix.identity
      curr_mat *= Geo3d::Matrix.rotation_x curr_state["rx"].degrees
      curr_mat *= Geo3d::Matrix.rotation_y curr_state["ry"].degrees
      curr_mat *= Geo3d::Matrix.rotation_z curr_state["rz"].degrees

      next_pos = Geo3d::Vector.new next_state["x"], next_state["y"], next_state["z"]
      next_mat = Geo3d::Matrix.identity
      next_mat *= Geo3d::Matrix.rotation_x next_state["rx"].degrees
      next_mat *= Geo3d::Matrix.rotation_y next_state["ry"].degrees
      next_mat *= Geo3d::Matrix.rotation_z next_state["rz"].degrees

      local_velocity = curr_mat.inverse * (next_pos - curr_pos) / timestep_in_sec
      rotation_diff = curr_mat.inverse * next_mat
      global_x_axis = Geo3d::Vector.new 1, 0, 0
      diff_x_axis = rotation_diff * global_x_axis
      rz_diff = Math.acos(diff_x_axis.normalize.dot global_x_axis)
      if diff_x_axis.y < 0
        rz_diff = -rz_diff
      end

      {
        :t   => curr_state["t"],
        :dx  => clip(local_velocity.x, 15.0), # Will convert into Roll in client
        :dy  => clip(local_velocity.y, 15.0), # Will convert into Pitch in client
        :dz  => clip(local_velocity.z,  4.0), # Will convert into Throttle in client
        :drz => clip(rz_diff.to_degrees / timestep_in_sec, 100.0), # Will convert into Yaw in client
      }
    end
  end

  def diff_states_to_commands(diff_states)
    diff_states.map do |diff_state|
      {
        :t   => diff_state["t"],
        :dx  => normalized_clip(diff_state["dx"],   15.0), # Will convert into Roll in client
        :dy  => normalized_clip(diff_state["dy"],   15.0), # Will convert into Pitch in client
        :dz  => normalized_clip(diff_state["dz"],    4.0), # Will convert into Throttle in client
        :drz => normalized_clip(diff_state["drz"], 100.0), # Will convert into Yaw in client
      }
    end
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

  ## Serialization ##
  def serialize_episode (episode)
    {
      :id             => episode.id,
      :name           => episode.name,
      :timestep       => episode.timestep,
      :states         => JSON.parse(episode.states),
      :diff_states    => JSON.parse(episode.diff_states),
      :commands       => JSON.parse(episode.commands),
      :simulator_logs => JSON.parse(episode.simulator_logs),
      :created_at     => episode.created_at,
      :updated_at     => episode.updated_at,
    }
  end

  def serialize_optimization (optimization)
    {
      :episode                  => serialize_episode(optimization.episode),
      :states_list              => JSON.parse(optimization.states_list),
      :commands_list            => JSON.parse(optimization.commands_list),
      :simulator_log_list       => JSON.parse(optimization.simulator_log_list),
      :max_iteration_count      => optimization.max_iteration_count,
      :current_iteration_index  => optimization.current_iteration_index,
      :created_at               => optimization.created_at,
      :updated_at               => optimization.updated_at,
    }
  end
end
