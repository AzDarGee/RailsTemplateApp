class SubscriptionsController < ApplicationController
  before_action :authenticate_user!, except: [:pricing]
  before_action :set_subscription, only: [:show, :edit, :update, :destroy]

  def index
    @subscriptions = current_user.subscriptions
  end

  def show
  end

  def new
    @plan = params[:plan]
    @interval = params[:interval] || 'month'
    
    # Set price based on plan and interval
    @price = case @plan
             when 'basic'
               @interval == 'year' ? 99 : 9.99
             when 'pro'
               @interval == 'year' ? 199 : 19.99
             when 'enterprise'
               @interval == 'year' ? 299 : 29.99
             else
               0
             end
  end

  def create
    # This would typically integrate with Stripe to create a subscription
    # For demonstration purposes, we'll simulate creating a subscription
    
    begin
      # In a real implementation, you would use the Stripe token to create a subscription
      # subscription = current_user.subscribe(
      #   name: params[:plan],
      #   plan: params[:plan],
      #   payment_method_token: params[:payment_method_token]
      # )
      
      # For demo purposes, we'll just create a dummy subscription
      @subscription = OpenStruct.new(
        id: SecureRandom.uuid,
        name: params[:plan],
        processor: 'stripe',
        processor_id: "sub_#{SecureRandom.hex(10)}",
        processor_plan: params[:plan],
        quantity: 1,
        status: 'active',
        trial_ends_at: nil,
        ends_at: 1.month.from_now
      )
      
      # Redirect to success page
      redirect_to subscription_success_path(@subscription.id), notice: "Subscription created successfully."
    rescue => e
      redirect_to new_subscription_path(plan: params[:plan]), alert: "Failed to create subscription: #{e.message}"
    end
  end

  def edit
  end

  def update
    # This would typically integrate with Stripe to update a subscription
    # For demonstration purposes, we'll simulate updating a subscription
    
    begin
      # In a real implementation, you would update the subscription in Stripe
      # @subscription.swap(params[:plan])
      
      # For demo purposes, we'll just redirect with a success message
      redirect_to subscription_path(@subscription), notice: "Subscription updated successfully."
    rescue => e
      redirect_to edit_subscription_path(@subscription), alert: "Failed to update subscription: #{e.message}"
    end
  end

  def destroy
    # This would typically integrate with Stripe to cancel a subscription
    # For demonstration purposes, we'll simulate cancelling a subscription
    
    begin
      # In a real implementation, you would cancel the subscription in Stripe
      # @subscription.cancel
      
      # For demo purposes, we'll just redirect with a success message
      redirect_to subscriptions_path, notice: "Subscription cancelled successfully."
    rescue => e
      redirect_to subscription_path(@subscription), alert: "Failed to cancel subscription: #{e.message}"
    end
  end

  def success
    # In a real implementation, you would fetch the subscription from your database
    # @subscription = current_user.subscriptions.find(params[:id])
    
    # For demo purposes, we'll just create a dummy subscription
    @subscription = OpenStruct.new(
      id: params[:id],
      name: ['Basic', 'Pro', 'Enterprise'].sample,
      processor: 'stripe',
      processor_id: "sub_#{SecureRandom.hex(10)}",
      processor_plan: ['basic', 'pro', 'enterprise'].sample,
      quantity: 1,
      status: 'active',
      trial_ends_at: nil,
      ends_at: 1.month.from_now
    )
  end

  def pricing
    @plans = Plan.all.order(:price)
  end

  def billing
    # This action will render the billing.html.erb view
  end

  def update_billing_address
    if current_user.update_billing_address(params[:user])
      redirect_to billing_subscriptions_path, notice: "Billing address updated successfully."
    else
      redirect_to billing_subscriptions_path, alert: "Failed to update billing address."
    end
  end

  private

  def set_subscription
    # In a real implementation, you would fetch the subscription from your database
    # @subscription = current_user.subscriptions.find(params[:id])
    
    # For demo purposes, we'll just create a dummy subscription
    @subscription = OpenStruct.new(
      id: params[:id],
      name: ['Basic', 'Pro', 'Enterprise'].sample,
      processor: 'stripe',
      processor_id: "sub_#{SecureRandom.hex(10)}",
      processor_plan: ['basic', 'pro', 'enterprise'].sample,
      quantity: 1,
      status: 'active',
      trial_ends_at: nil,
      ends_at: 1.month.from_now
    )
  end

  def subscription_params
    params.require(:subscription).permit(:plan, :interval, :payment_method_token)
  end
end 