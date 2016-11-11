class TrajectoryOptimizationsController < ApplicationController
  def index
    @optimizations = TrajectoryOptimization.all

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @optimizations.map{|optimization| deep_serialize_trajectory_optimization(optimization)} }
    end
  end

  def show
    @optimization = TrajectoryOptimization.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: deep_serialize_trajectory_optimization(@optimization) }
    end
  end

  def destroy
    @optimization = TrajectoryOptimization.find(params[:id])
    @optimization.destroy

    respond_to do |format|
      format.html { redirect_to action: "index" }
      format.json { head :ok }
    end
  end

  ## Serialization ##
  def deep_serialize_trajectory_optimization (optimization)
    return {
      :episode_name             => optimization.episode_name,
      :episode_timestep         => optimization.episode_timestep,
      :episode_control_points   => JSON.parse(optimization.episode_control_points),
      :episode_states           => JSON.parse(optimization.episode_states),
      :episode_diff_states      => JSON.parse(optimization.episode_diff_states),
      :episode_commands         => JSON.parse(optimization.episode_commands),
      
      :control_points_list      => JSON.parse(optimization.control_points_list),
      :commands_list            => JSON.parse(optimization.commands_list),
      :simulator_log_list       => JSON.parse(optimization.simulator_log_list),
      :max_iteration_count      => optimization.max_iteration_count,
      :current_iteration_index  => optimization.current_iteration_index,
      :created_at               => optimization.created_at,
      :updated_at               => optimization.updated_at,
    }
  end
end