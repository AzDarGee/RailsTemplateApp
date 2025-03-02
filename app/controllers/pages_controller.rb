class PagesController < ApplicationController
  before_action :authenticate_user!, only: [:dashboard]
  
  def home
  end

  def about
  end

  def contact
  end

  def pricing
  end
  
  def dashboard
    # This action will render the dashboard.html.erb view
  end
  
  def terms
  end
  
  def privacy
  end
end
