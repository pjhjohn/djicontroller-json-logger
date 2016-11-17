class EpisodesController < ApplicationController
  def index
    @episodes = Episode.all

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @episodes.map{|episode| serialize_episode(episode)} }
    end
  end

  def new
    @episode = Episode.new

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: serialize_episode(@episode) }
    end
  end

  def create
    @episode = Episode.new
    @episode.name = params[:name]
    @episode.timestep = clip(params[:timestep].to_i, 80, 120) unless params[:timestep].nil?
    @episode.states = JSON.parse(params[:states]).to_json # Checks JSON validity during conversion

    respond_to do |format|
      if @episode.save
        update_episode_diff_states(@episode)
        update_episode_commands(@episode)
        flash[:notice] = 'Episode was successfully created.'
        format.html { redirect_to(@episode) }
        format.json { render json: serialize_episode(@episode), status: :created, location: @episode }
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
      format.json { render json: serialize_episode(@episode) }
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
    # episode_params[:states] = JSON.parse(params[:states]).to_json # Checks JSON validity during conversion

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
        format.json { render json: serialize_episode(@episode), status: :created, location: @episode }
      else
        format.html { render action: 'new' }
        format.json { render json: @episode.errors, status: :unprocessable_entity }
      end
    end
  end

  def render3d
    @episode = Episode.find(params[:id])

    respond_to do |format|
      format.html # render.html.erb
      format.json { render json: serialize_episode(@episode) }
    end
  end

  ## Actions for Episode Data Update ##
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
    episode_params[:simulator_logs] = JSON.parse(@episode.simulator_logs).push(params[:events]).to_json unless params[:events].nil?

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
  def update_episode_diff_states(episode)
    episode.diff_states = states_to_diff_states(JSON.parse(episode.states), episode.timestep).to_json
    return episode.save
  end

  def update_episode_commands(episode)
    episode.commands = diff_states_to_commands(JSON.parse(episode.diff_states)).to_json
    return episode.save
  end
end