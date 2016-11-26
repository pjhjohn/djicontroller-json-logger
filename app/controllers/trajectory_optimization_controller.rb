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
    @optimization.states_list = [objectify_json(@episode.states)].to_json
    @optimization.commands_list = [objectify_json(@episode.commands)].to_json
    @optimization.max_iteration_count = params[:max_iteration_count] unless params[:max_iteration_count].nil?

    # Save
    @optimization.save

    # Construct Feedback Object & Return with JSON format
    render :json => objectify_optimization_to_feedback_form(@optimization)
  end

  # params[:id] is TrajectoryOptimization ID
  def continue
    # Retrieve Target TrajectoryOptimization
    @optimization = TrajectoryOptimization.find(params[:id])

    # Push to update simulator_log_list from client
    @optimization.simulator_log_list = objectify_json(@optimization.simulator_log_list).push(params[:events]).to_json

    # Instantiate data for current iteration
    timestep            = @optimization.episode.timestep
    current             = @optimization.current_iteration_index
    max                 = @optimization.max_iteration_count
    states_list         = objectify_json(@optimization.states_list)
    commands_list       = objectify_json(@optimization.commands_list)
    simulator_log_list  = objectify_json(@optimization.simulator_log_list)

    # Calculate difference factor from current states & simulator_log
    differences = differences_between states_list[current], simulator_log_list[current]

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
    render :json => objectify_optimization_to_feedback_form(@optimization)
  end

  # Difference from reference state to simulator state
  def difference_between(ref_state, sim_state)
    ref_position, ref_rotation = state_to_position_and_rotation(ref_state)
    sim_position, sim_rotation = state_to_position_and_rotation(sim_state)
    {
      :t => ref_state["t"],
      :position => sim_position - ref_position,
      :rotation => ref_rotation.inverse * sim_rotation,
    }
  end

  def differences_between(ref_states, sim_states)
    # TODO : sim_states.length => ref_states.length
    (0...sim_states.length).map do |i|
      difference_between ref_states[i], sim_states[i]
    end
  end

  # Distance as score blending position & rotation SQUARED difference factors
  def difference_to_distance(difference)
    @@const.mixratio * @@const.position * difference.position.length_squared +                                  # ||dP||^2
    (1 - @@const.mixratio) * @@const.rotation * (Geo3d::Quaternion.from_matrix(difference.rotation).angle ** 2) # ||dR||^2 angle in radians
  end

  # RMS (S from difference_to_distance)
  def error_score(ref_states, sim_states)
    score = 0
    differences_between(ref_states, sim_states).each { |difference| score += difference_to_distance(distance) }
    Math.sqrt(score / ref_states.length)
  end

  def get_delta_states_to_update(states, distances)
    nil # TODO : implement this
  end

  def update_states(states, delta_states)
    states # TODO : implement this
  end

  # States Refinements
  def refine_states(states)
    bias_pos, _ = state_to_position_and_rotation(states[0])
    bias_mat = Geo3d::Matrix.rotation_z states[0]["rz"].degrees
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
end
