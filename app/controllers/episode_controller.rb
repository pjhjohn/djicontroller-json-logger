class EpisodeController < ApplicationController
  def index
    @episodes = Episode.all
  
    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render xml: @episodess }
    end
  end
  
  def new
    @episode = Episode.new
  
    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render xml: @episode }
    end
  end
  
  def create
    @episode = Episode.new(episode_params)
  
    respond_to do |format|
      if @episode.save
        flash[:notice] = 'Episode was successfully created.'
        format.html { redirect_to(@episode) }
        format.xml  { render xml: @episode, status: :created, location: @episode }
      else
        format.html { render action: 'new' }
        format.xml  { render xml: @episode.errors, status: :unprocessable_entity }
      end
    end
  end
  
  def show
    @episode = Episode.find(params[:id])
  
    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render xml: @episode }
    end
  end
  
  def edit
    @episode = Episode.find(params[:id])
  end
  
  def update
    @episode = Episode.find(params[:id])
  
    respond_to do |format|
      if @episode.update(episode_params)
        flash[:notice] = 'Episode was successfully updated.'
        format.html { redirect_to(@episode) }
        format.xml  { head :ok }
      else
        format.html { render action: 'edit' }
        format.xml  { render xml: @episode.errors, status: :unprocessable_entity }
      end
    end
  end
  
  def destroy
    @episode = Episode.find(params[:id])
    @episode.destroy
  
    respond_to do |format|
      format.html { redirect_to(episodes_url) }
      format.xml  { head :ok }
    end
  end
end