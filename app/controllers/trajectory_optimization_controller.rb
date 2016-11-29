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

    refined_ref_states  = refine_states(objectify_json(@optimization.episode.states))
    refined_sim_states  = refine_states(simulator_log_list[current])

    differences = differences_between(refined_ref_states, refined_sim_states)
    updated_iter_states = refine_states(update_states(states_list[current], differences))

    # Next Iteration : update states & commands
    @optimization.states_list = states_list.push(updated_iter_states).to_json if current < max - 1
    @optimization.commands_list = commands_list.push(states_to_commands(updated_iter_states, timestep)).to_json if current < max - 1
    @optimization.current_iteration_index = current + 1
    @optimization.save

    # Construct Feedback Object & Return with JSON format
    render :json => objectify_optimization_to_feedback_form(@optimization)
  end

  # Difference from simulator state to reference state
  def difference_between(ref_state, sim_state)
    ref_position, ref_rotation = state_to_position_and_rotation(ref_state)
    sim_position, sim_rotation = state_to_position_and_rotation(sim_state)
    {
      :t => ref_state["t"],
      :position => ref_position - sim_position,
      :rotation => sim_rotation.inverse * ref_rotation,
    }
  end

  def differences_between(ref_states, sim_states)
    (0...ref_states.length).map do |i|
      difference = difference_between ref_states[i], sim_states[i]
      state_from_position_and_rotation difference[:t], difference[:position], difference[:rotation]
    end
  end

  # Distance as score blending position & rotation SQUARED difference factors
  def raw_distance_of_difference_position(position_diff)
    position_diff.length_squared
  end

  def raw_distance_of_difference_rotation(rotation_diff)
    (matrix_to_quaternion(rotation_diff).angle ** 2)
  end

  def difference_to_distance(difference)
    diff_position, diff_rotation = state_to_position_and_rotation(difference)
    @@const.mixratio * @@const.position * raw_distance_of_difference_position(diff_position) +     # ||dP||^2
    (1 - @@const.mixratio) * @@const.rotation * raw_distance_of_difference_rotation(diff_rotation) # ||dR||^2 angle in radians
  end

  # RMS (S from difference_to_distance)
  def error_score(differences)
    Math.sqrt(differences.inject(0){ |sum, difference| sum + difference_to_distance(difference) } / differences.length)
  end

  def update_state(iter_state, difference)
    iter_state_pos, iter_state_rot = state_to_position_and_rotation(iter_state)
    difference_pos, difference_rot = state_to_position_and_rotation(difference)

    iter_state_quaternion = matrix_to_quaternion(iter_state_rot)
    difference_quaternion = matrix_to_quaternion(difference_rot)

    updated_pos = iter_state_pos + difference_pos * @@const.update_damp
    updated_rot = (iter_state_quaternion + difference_quaternion * @@const.update_damp).to_matrix

    state_from_position_and_rotation iter_state["t"], updated_pos, updated_rot
  end

  def update_states(iter_states, differences)
    (0...iter_states.length).map do |i|
      if i < differences.length
        update_state(iter_states[i], differences[i])
      else
        iter_states[i]
      end
    end
  end
end
