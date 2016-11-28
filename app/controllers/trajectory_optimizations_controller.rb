class TrajectoryOptimizationsController < TrajectoryOptimizationController
  def index
    @optimizations = TrajectoryOptimization.all

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @optimizations.map{|optimization| objectify_optimization(optimization)} }
    end
  end

  def show
    @optimization = TrajectoryOptimization.find(params[:id])
    @optimization.simulator_log_list = objectify_json(@optimization.simulator_log_list).map do |states|
      refine_states(states)
    end.to_json

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: objectify_optimization(@optimization) }
    end
  end

  def destroy
    @optimization = TrajectoryOptimization.find(params[:id])
    @optimization.destroy

    respond_to do |format|
      format.html { redirect_to(trajectory_optimizations_url) }
      format.json { head :ok }
    end
  end

  def duplicate
    @optimization = TrajectoryOptimization.find(params[:id]).dup

    respond_to do |format|
      if @optimization.save
        flash[:notice] = 'optimization was successfully duplicated.'
        format.html { redirect_to(@optimization) }
        format.json { render json: objectify_optimization(@optimization), status: :created, location: @optimization }
      else
        format.html { redirect_to :back }
        format.json { render json: @optimization.errors, status: :unprocessable_entity }
      end
    end
  end

  def iteration_show
    @optimization = TrajectoryOptimization.find(params[:id])
    @iteration_id = params[:iteration_id].to_i

    refined_ref_states = refine_states(objectify_json(@optimization.episode.states))
    refined_iter_states = refine_states(objectify_json(@optimization.states_list)[@iteration_id])
    refined_sim_states = refine_states(objectify_json(@optimization.simulator_log_list)[@iteration_id])
    differences = differences_between(refined_ref_states, refined_sim_states)
    updated_iter_states = refine_states(update_states(objectify_json(@optimization.states_list)[@iteration_id], differences))

    @chart_data = [
      refined_ref_states,
      refined_iter_states,
      refined_sim_states,
      differences,
      updated_iter_states,
    ].to_json
    @code_data = @chart_data

    respond_to do |format|
      format.html # iteration_show.html.erb
      format.json { render json: objectify_optimization(@optimization) }
    end
  end

  def iteration_render3d
    @optimization = TrajectoryOptimization.find(params[:id])
    @iteration_id = params[:iteration_id].to_i

    @refined_ref_states = refine_states(objectify_json(@optimization.episode.states)).to_json
    @refined_iter_states = refine_states(objectify_json(@optimization.states_list)[@iteration_id]).to_json
    @refined_sim_states = refine_states(objectify_json(@optimization.simulator_log_list)[@iteration_id]).to_json

    @differences = differences_between(objectify_json(@refined_ref_states), objectify_json(@refined_sim_states)).to_json
    @updated_iter_states = refine_states(update_states(objectify_json(@optimization.states_list)[@iteration_id], objectify_json(@differences))).to_json

    respond_to do |format|
      format.html # iteration_render3d.html.erb
      format.json { render json: objectify_optimization(@optimization) }
    end
  end
end
