class PagesController < ApplicationController
  before_action :authenticate_user!, only: [:dashboard]
  
  def home
  end

  def about
  end

  def contact
  end

  def pricing
    @plans = Plan.all.order(:price)
    # If you're using a specific structure, you might need something like:
    # @plans = {
    #   basic: Plan.find_by(name: 'Basic'),
    #   pro: Plan.find_by(name: 'Pro'),
    #   enterprise: Plan.find_by(name: 'Enterprise')
    # }
  end
  
  def dashboard
    # This action will render the dashboard.html.erb view
  end
  
  def terms
  end
  
  def privacy
  end
end
