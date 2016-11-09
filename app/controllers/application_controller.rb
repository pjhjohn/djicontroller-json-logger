class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  # protect_from_forgery with: :exception

  ## Functions for Episode Data Update ##
  def update_episode_states(episode)
    control_points = JSON.parse(episode.control_points)
    bez = Bezier::Curve.new(*control_points.map{ |point| [point["x"], point["y"], point["z"], point["r"]]})
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
        :r => point.r,
      })
      time += episode.timestep
    end

    episode.states = states.to_json
    episode.save
  end

  def update_episode_diff_states(episode)
    states = JSON.parse(episode.states)

    diff_states = (1...states.length).map do |i|
      prev, curr, timestep_s = states[i-1], states[i], episode.timestep / 1000.0

      # Position Coordinate : World -> Body
      dx = (curr["x"] - prev["x"]) / timestep_s
      dy = (curr["y"] - prev["y"]) / timestep_s
      dz = (curr["z"] - prev["z"]) / timestep_s
      v_body = Roto.rotate(
        [dx, dy, dz],                                       # Point to rotate
        (180 / Math::PI) * Math.atan2(dy, dx) - prev["r"],  # Rotation angle
        [0, 0, 1]                                           # Rotation axis
      )

      {
        :t  => prev["t"],
        :dx => clip(v_body[0],                             15.0), # Will convert into Roll
        :dy => clip(v_body[1],                             15.0), # Will convert into Pitch
        :dz => clip(v_body[2],                              4.0), # Will convert into Throttle
        :w  => clip((curr["r"] - prev["r"]) / timestep_s, 100.0), # Will convert into Yaw
      }
    end

    episode.diff_states = diff_states.to_json
    episode.save
  end

  def update_episode_commands(episode)
    diff_states = JSON.parse(episode.diff_states)

    commands = diff_states.map do |diff_state|
      {
        :t        => diff_state["t"],
        :roll     => normalized_clip( diff_state["dx"],  15.0), # same axis : front
        :pitch    => normalized_clip(-diff_state["dy"],  15.0), # pitch axis towards right
        :throttle => normalized_clip( diff_state["dz"],   4.0), # same axis : altitude
        :yaw      => normalized_clip(-diff_state[ "w"], 100.0)  # yaw axis towards bottom
      }
    end

    episode.commands = commands.to_json
    episode.save
  end

  ## Calculations ##
  ## Limitations of Drone (both positive & negative)
  # Yaw : 100degrees/s
  # Pitch Roll : 15m/s
  # Throttle : 4m/s
  def clip(value, limit, offset = 0)
    clipped_val = value
    clipped_val = offset + limit if value > offset + limit
    clipped_val = offset - limit if value < offset - limit
    return clipped_val
  end

  def clipped?(value, limit, offset = 0)
    return value == clip(value, limit, offset)
  end

  def normalized_clip(value, limit)
    return clip(value, limit) / limit
  end

  ## Serialization ##
  def json_deep_serialize (episode)
    return {
      :id             => episode.id,
      :name           => episode.name,
      :timestep       => episode.timestep,
      :control_points => JSON.parse(episode.control_points),
      :states         => JSON.parse(episode.states),
      :diff_states    => JSON.parse(episode.diff_states),
      :commands       => JSON.parse(episode.commands),
      :simulator_logs => JSON.parse(episode.simulator_logs),
      :created_at     => episode.created_at,
      :updated_at     => episode.updated_at,
    }
  end
end
