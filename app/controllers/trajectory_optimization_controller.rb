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
    render :json => build_trajectory_optimization_feedback(@optimization)
  end

  # params[:id] is TrajectoryOptimization ID
  def continue
    # Retrieve Target TrajectoryOptimization
    @optimization = TrajectoryOptimization.find(params[:id])

    # Push to update simulator_log_list from client
    @optimization.simulator_log_list = JSON.parse(@optimization.simulator_log_list).push(params[:events]).to_json

    # Instantiate data for current iteration
    timestep  = @optimization.episode.timestep
    current   = @optimization.current_iteration_index
    max       = @optimization.max_iteration_count
    states_list         = JSON.parse(@optimization.states_list)
    commands_list       = JSON.parse(@optimization.commands_list)
    simulator_log_list  = JSON.parse(@optimization.simulator_log_list)

    # Calculate difference factor from current states & simulator_log
    error = error_against_reference(states_list[current], simulator_log_list)

    # Calculate update difference of current states
    diff_states = diff_states_to_update(states_list[current], error)

    # Next Iteration : update states & commands
    if current < max - 1
      @optimization.states_list = states_list.push(update_states(states_list[current], diff_states)).to_json # TODO : update from diff_states
      @optimization.commands_list = commands_list.push(states_to_commands(states_list[current], timestep)).to_json
    end
    @optimization.current_iteration_index = current + 1
    @optimization.save

    # Construct Feedback Object & Return with JSON format
    render :json => build_trajectory_optimization_feedback(@optimization)
  end

  def error_against_reference(states, simulator_log)
    return nil # TODO : implement this
  end

  def diff_states_to_update (states, error)
    return nil # TODO : implement this
  end

  def update_states(states, diff_states)
    return states # TODO : implement this
  end

  def build_trajectory_optimization_feedback(optimization)
    current, max = optimization.current_iteration_index, optimization.max_iteration_count
    return {
      :id => optimization.id,
      :current_iteration_index => current,
      :timestep => optimization.episode.timestep,
      :success => true, # TODO : implement this
      :commands => current >= max ? [] : JSON.parse(optimization.commands_list)[current],
      :error_message => "Error Message!!" # TODO : implement this
    }
  end
end
