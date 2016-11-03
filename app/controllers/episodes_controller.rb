class EpisodesController < ApplicationController
  def index
    @episodes = Episode.all
  
    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @episodes }
    end
  end
  
  def new
    @episode = Episode.new
  
    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @episode }
    end
  end
  
  def create
    @episode = Episode.new
    @episode.name = params[:name]
    @episode.timestep = params[:timestep] unless params[:timestep].nil?
    @episode.control_points = JSON.parse(params[:control_points]).to_json # Checks JSON validity during conversion

    respond_to do |format|
      if @episode.save
        flash[:notice] = 'Episode was successfully created.'
        format.html { redirect_to(@episode) }
        format.json { render json: @episode, status: :created, location: @episode }
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
      format.json { render json: @episode }
    end
  end
  
  def edit
    @episode = Episode.find(params[:id])
  end
  
  def update
    @episode = Episode.find(params[:id])

    episode_params = Hash.new
    episode_params[:name] = params[:name] unless params[:name].nil?
    episode_params[:timestep] = params[:timestep] unless params[:timestep].nil?
    episode_params[:control_points] = JSON.parse(params[:control_points]).to_json # Checks JSON validity during conversion
  
    respond_to do |format|
      if @episode.update(episode_params)
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

  def update_states
    @episode = Episode.find(params[:id])
    control_points = JSON.parse(@episode.control_points)
    bez = Bezier::Curve.new(*control_points.map{ |point| [point["x"], point["y"], point["z"], point["r"]]})
    max_time = control_points.last["t"]

    states = []
    time = 0
    while time <= max_time do
      point = bez.point_on_curve(time / max_time)
      states.push({
        :t => time,
        :x => point.x,
        :y => point.y,
        :z => point.z,
        :r => point.r,
      })
      time += @episode.timestep
    end

    @episode.states = states.to_json
    @episode.save

    redirect_to(@episode)
  end
end