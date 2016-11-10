class TrajectoryOptimizationController < ApplicationController
  # Assume Requests are in JSON format

  # Created TrajectoryOptimization Row
  # params[:id] is Episode ID
  def init
    # Retrieve Target Episode
    @episode = Episode.find(params[:id])

    # Instantiate TrajectoryOptimization
    @optimization = TrajectoryOptimization.new

    # Direct Copy from @episode
    @optimization.episode_name = @episode.name
    @optimization.episode_timestep = @episode.timestep
    @optimization.episode_control_points = @episode.control_points
    @optimization.episode_states = @episode.states
    @optimization.episode_diff_states = @episode.diff_states
    @optimization.episode_commands = @episode.commands

    # Initialization of TrajectoryOptimization Environments
    @optimization.control_points_list = [JSON.parse(@episode.control_points)].to_json
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
    @optimization.save

    # Instantiate data for current iteration
    timestep  = @optimization.episode_timestep
    current   = @optimization.current_iteration_index
    max       = @optimization.max_iteration_count
    control_points_list = JSON.parse(@optimization.control_points_list)
    commands_list       = JSON.parse(@optimization.commands_list)
    simulator_log_list  = JSON.parse(@optimization.simulator_log_list)

    # Calculate difference factor from current control_points & simulator_log
    error = error_against_reference(control_points_list[current], simulator_log_list)

    # Calculate update difference of current control_points
    diff_control_points = diff_control_points_to_update(control_points_list[current], error)

    # Next Iteration : update control_points & commands
    if current < max - 1
      @optimization.control_points_list = control_points_list.push(update_control_points(control_points_list[current], diff_control_points)).to_json # TODO : update from diff_control_points
      @optimization.commands_list = commands_list.push(control_points_to_commands(control_points_list[current], timestep)).to_json
    end
    @optimization.current_iteration_index = current + 1
    @optimization.save

    # Construct Feedback Object & Return with JSON format
    render :json => build_trajectory_optimization_feedback(@optimization)
  end

  def error_against_reference(control_points, simulator_log)
    return nil # TODO : implement this
  end

  def diff_control_points_to_update (control_points, error)
    return nil # TODO : implement this
  end

  def update_control_points(control_points, diff_control_points)
    return control_points # TODO : implement this
  end

  def build_trajectory_optimization_feedback(optimization)
    current, max = optimization.current_iteration_index, optimization.max_iteration_count
    return {
      :id => optimization.id,
      :current_iteration_index => current,
      :timestep => optimization.episode_timestep,
      :success => true, # TODO : implement this
      :commands => current >= max ? [] : JSON.parse(optimization.commands_list)[current],
      :error_message => "Error Message!!" # TODO : implement this
    }
  end
end
