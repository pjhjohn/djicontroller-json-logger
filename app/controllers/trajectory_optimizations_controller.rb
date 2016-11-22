class TrajectoryOptimizationsController < ApplicationController
  def index
    @optimizations = TrajectoryOptimization.all

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @optimizations.map{|optimization| serialize_optimization(optimization)} }
    end
  end

  def show
    @optimization = TrajectoryOptimization.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: serialize_optimization(@optimization) }
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

  def iteration_show
    @optimization = TrajectoryOptimization.find(params[:id])
    @iteration_id = params[:iteration_id].to_i

    respond_to do |format|
      format.html # iteration_show.html.erb
      format.json { render json: serialize_optimization(@optimization) }
    end
  end

  def iteration_render3d
    @optimization = TrajectoryOptimization.find(params[:id])
    @iteration_id = params[:iteration_id].to_i

    respond_to do |format|
      format.html # iteration_render3d.html.erb
      format.json { render json: serialize_optimization(@optimization) }
    end
  end
end