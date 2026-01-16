class ModelsController < ApplicationController
  def index
    @models = Model.where(provider: "openrouter")
  end

  def show
    @model = Model.find(params[:id])
  end

  def refresh
    Model.refresh!
    redirect_to models_path, notice: "Models refreshed successfully"
  end
end