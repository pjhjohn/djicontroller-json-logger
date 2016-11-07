class EpisodesController < ApplicationController
  def index
    @episodes = Episode.all

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @episodes.map{|episode| json_deep_serialize(episode)} }
    end
  end

  def new
    @episode = Episode.new

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: json_deep_serialize(@episode) }
    end
  end

  def create
    @episode = Episode.new
    @episode.name = params[:name]
    @episode.timestep = clip(params[:timestep].to_i, 80, 120) unless params[:timestep].nil?
    @episode.control_points = JSON.parse(params[:control_points]).to_json # Checks JSON validity during conversion

    respond_to do |format|
      if @episode.save
        update_episode_states(@episode)
        update_episode_diff_states(@episode)
        update_episode_commands(@episode)
        flash[:notice] = 'Episode was successfully created.'
        format.html { redirect_to(@episode) }
        format.json { render json: json_deep_serialize(@episode), status: :created, location: @episode }
      else
        format.html { render action: 'new' }
        format.json { render json: @episode.errors, status: :unprocessable_entity }
      end
    end
  end
  
  def show
    @episode = Episode.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: json_deep_serialize(@episode) }
    end
  end
  
  def edit
    @episode = Episode.find(params[:id])
  end
  
  def update
    @episode = Episode.find(params[:id])

    episode_params = Hash.new
    episode_params[:name] = params[:name] unless params[:name].nil?
    episode_params[:timestep] = clip(params[:timestep].to_i, 80, 120) unless params[:timestep].nil?
    episode_params[:control_points] = JSON.parse(params[:control_points]).to_json # Checks JSON validity during conversion

    respond_to do |format|
      if @episode.update(episode_params)
        update_episode_states(@episode)
        update_episode_diff_states(@episode)
        update_episode_commands(@episode)
        flash[:notice] = 'Episode was successfully updated.'
        format.html { redirect_to(@episode) }
        format.json { head :ok }
      else
        format.html { render action: 'edit' }
        format.json { render json: @episode.errors, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    @episode = Episode.find(params[:id])
    @episode.destroy
  
    respond_to do |format|
      format.html { redirect_to(episodes_url) }
      format.json { head :ok }
    end
  end

  ## Actions for Episode Data Update ##
  def update_states
    @episode = Episode.find(params[:id])
    update_episode_states(@episode)
    update_episode_diff_states(@episode)
    update_episode_commands(@episode)
    redirect_to(@episode)
  end

  def update_diff_states
    @episode = Episode.find(params[:id])
    update_episode_diff_states(@episode)
    update_episode_commands(@episode)
    redirect_to(@episode)
  end

  def update_commands
    @episode = Episode.find(params[:id])
    update_episode_commands(@episode)
    redirect_to(@episode)
  end

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
      :created_at     => episode.created_at,
      :updated_at     => episode.updated_at,
    }
  end
end