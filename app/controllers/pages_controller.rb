class PagesController < ApplicationController
  before_action :authenticate_user!, only: [:dashboard, :dashboard_section]

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
  
  def terms
  end
  
  def privacy
  end
  
  def dashboard
    # Default to overview section
    @section = "overview"
    render "dashboard"
    
  end
   
  def dashboard_section
    @section = params[:section]

    case @section
    when "overview"

    when "ai_agents"
      @agents = current_user.agents.order(created_at: :desc)
    when "subscriptions"
      @subscriptions = current_user.subscriptions.order(created_at: :desc)
    when "billing"
      # Billing section data
    when "payment_history"
      @charges = current_user.charges.order(created_at: :desc)
    else
      redirect_to pages_dashboard_path
      return
    end
    
    respond_to do |format|
      format.turbo_stream { 
        render turbo_stream: turbo_stream.replace(
          "dashboard_content", 
          partial: "pages/dashboard_sections/#{@section}",
          locals: { section: @section }
        )
      }
    end
  rescue ActionView::MissingTemplate => e
    Rails.logger.error("Missing template: #{e.message}")
    redirect_to pages_dashboard_path, alert: "That section is not available."
  end

end
