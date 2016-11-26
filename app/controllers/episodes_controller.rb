class EpisodesController < ApplicationController
  def index
    @episodes = Episode.all

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @episodes.map{|episode| objectify_episode(episode)} }
    end
  end

  def new
    @episode = Episode.new

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: objectify_episode(@episode) }
    end
  end

  def new_with_control_points
    @episode = Episode.new

    respond_to do |format|
      format.html # new_with_control_points.html.erb
      format.json { render json: objectify_episode(@episode) }
    end
  end

  def create
    @episode = Episode.new
    @episode.name = params[:name]
    @episode.timestep = clip(params[:timestep].to_i, 80, 120) unless params[:timestep].nil?
    @episode.states = objectify_json(params[:states]).to_json # Checks JSON validity during conversion

    respond_to do |format|
      if @episode.save
        update_episode_diff_states(@episode)
        update_episode_commands(@episode)
        flash[:notice] = 'Episode was successfully created.'
        format.html { redirect_to(@episode) }
        format.json { render json: objectify_episode(@episode), status: :created, location: @episode }
      else
        format.html { render action: 'new' }
        format.json { render json: @episode.errors, status: :unprocessable_entity }
      end
    end
  end

  def create_with_control_points
    @episode = Episode.new
    @episode.name = params[:name]
    @episode.timestep = clip(params[:timestep].to_i, 80, 120) unless params[:timestep].nil?
    @episode.control_points = objectify_json(params[:control_points]).to_json # Checks JSON validity during conversion

    respond_to do |format|
      if @episode.save
        update_episode_states(@episode)
        update_episode_diff_states(@episode)
        update_episode_commands(@episode)
        flash[:notice] = 'Episode was successfully created.'
        format.html { redirect_to(@episode) }
        format.json { render json: objectify_episode(@episode), status: :created, location: @episode }
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
      format.json { render json: objectify_episode(@episode) }
    end
  end

  def edit
    @episode = Episode.find(params[:id])
  end

  def update
    @episode = Episode.find(params[:id])

    episode_params = Hash.new
    # episode_params[:name] = params[:name] unless params[:name].nil?
    # episode_params[:timestep] = clip(params[:timestep].to_i, 80, 120) unless params[:timestep].nil?
    # episode_params[:states] = deserialize(params[:states]).to_json # Checks JSON validity during conversion

    respond_to do |format|
      if @episode.update(episode_params)
        # update_episode_diff_states(@episode)
        # update_episode_commands(@episode)
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

  def duplicate
    @episode = Episode.find(params[:id]).dup

    respond_to do |format|
      if @episode.save
        flash[:notice] = 'Episode was successfully duplicated.'
        format.html { redirect_to(@episode) }
        format.json { render json: objectify_episode(@episode), status: :created, location: @episode }
      else
        format.html { redirect_to :back }
        format.json { render json: @episode.errors, status: :unprocessable_entity }
      end
    end
  end

  def render3d
    @episode = Episode.find(params[:id])

    respond_to do |format|
      format.html # render.html.erb
      format.json { render json: objectify_episode(@episode) }
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

  def update_simulator_log # Assume accept only json request from android client
    @episode = Episode.find(params[:id])
    episode_params = Hash.new
    episode_params[:simulator_logs] = objectify_json(@episode.simulator_logs).push(params[:events]).to_json unless params[:events].nil?

    respond_to do |format|
      if @episode.update(episode_params)
        flash[:notice] = 'Simulator Log has been successfully pushed.'
        format.html { redirect_to(@episode) }
        format.json { head :ok }
      else
        format.html { render action: 'show' }
        format.json { render json: @episode.errors, status: :unprocessable_entity }
      end
    end
  end

  ## Alias shortcut functions for updating episode data ##
  def update_episode_states(episode)
    episode.states = control_points_to_states(objectify_json(episode.control_points), episode.timestep).to_json
    episode.save
  end

  def update_episode_diff_states(episode)
    episode.diff_states = states_to_diff_states(objectify_json(episode.states), episode.timestep).to_json
    episode.save
  end

  def update_episode_commands(episode)
    episode.commands = diff_states_to_commands(objectify_json(episode.diff_states)).to_json
    episode.save
  end
end
