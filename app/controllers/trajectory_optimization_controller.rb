class TrajectoryOptimizationController < ApplicationController
  # Assume Requests are in JSON format

  # Created TrajectoryOptimization Row
  # params[:id] is Episode ID
  def init
    # Retrieve Target Episode
    @episode = Episode.find(params[:id])

    # Instantiate TrajectoryOptimization
    @optimization = TrajectoryOptimization.new
    @optimization.episode_id = @episode.id

    # Initialization of TrajectoryOptimization Environments
    @optimization.states_list = [JSON.parse(@episode.states)].to_json
    @optimization.commands_list = [JSON.parse(@episode.commands)].to_json
    @optimization.max_iteration_count = params[:max_iteration_count] unless params[:max_iteration_count].nil?

    # Save
    @optimization.save

    # Construct Feedback Object & Return with JSON format
    render :json => build_optimization_feedback(@optimization)
  end

  # params[:id] is TrajectoryOptimization ID
  def continue
    # Retrieve Target TrajectoryOptimization
    @optimization = TrajectoryOptimization.find(params[:id])

    # Push to update simulator_log_list from client
    @optimization.simulator_log_list = JSON.parse(@optimization.simulator_log_list).push(params[:events]).to_json

    # Instantiate data for current iteration
    timestep            = @optimization.episode.timestep
    current             = @optimization.current_iteration_index
    max                 = @optimization.max_iteration_count
    states_list         = JSON.parse(@optimization.states_list)
    commands_list       = JSON.parse(@optimization.commands_list)
    simulator_log_list  = JSON.parse(@optimization.simulator_log_list)

    # Calculate difference factor from current states & simulator_log
    distances = get_distances(states_list[current], simulator_log_list[current])

    # Calculate update difference of current states
    delta_states = get_delta_states_to_update(states_list[current], distances)

    # Next Iteration : update states & commands
    if current < max - 1
      @optimization.states_list = states_list.push(update_states(states_list[current], delta_states)).to_json # TODO : update from delta_states
      @optimization.commands_list = commands_list.push(states_to_commands(states_list[current], timestep)).to_json
    end
    @optimization.current_iteration_index = current + 1
    @optimization.save

    # Construct Feedback Object & Return with JSON format
    render :json => build_optimization_feedback(@optimization)
  end

  def refine_states(states)
    bias_pos, bias_mat = state_to_position_and_rotation(states[0])
    states.map do |state|
      pos, mat = state_to_position_and_rotation(state)
      refined_pos = bias_mat.inverse * (pos - bias_pos)
      refined_mat = bias_mat.inverse * mat
      rx, ry, rz = matrix_to_euler(refined_mat)
      {
        :t => state["t"],
        :x => refined_pos.x,
        :y => refined_pos.y,
        :z => refined_pos.z,
        :rx => rx,
        :ry => ry,
        :rz => rz,
        :refined_pos => refined_pos,
        :refined_mat => refined_mat,
      }
    end
  end

  def get_distance(state1, state2)
    0 # TODO : implement this
  end

  def get_distances(states, simulator_log)
    # Assume states & simulator_log have same length & aligned
    (1..states.length).map do |i|
      get_distance(states[i], simulator_log[i])
    end
  end

  def error_score(states, simulator_log)
    score = 0
    get_distances(states, simulator_log).each { |distance| score += distance }
    score
  end

  def get_delta_states_to_update(states, distances)
    nil # TODO : implement this
  end

  def update_states(states, delta_states)
    states # TODO : implement this
  end

  def build_optimization_feedback(optimization)
    current, max = optimization.current_iteration_index, optimization.max_iteration_count
    {
      :id => optimization.id,
      :current_iteration_index => current,
      :timestep => optimization.episode.timestep,
      :commands => current >= max ? [] : JSON.parse(optimization.commands_list)[current], # Empty Commands considered as termination
      :success => true, # TODO : implement this
      :error_message => "Error Message!!" # TODO : implement this
    }
  end
end
