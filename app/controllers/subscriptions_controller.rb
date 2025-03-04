require 'ostruct'

class SubscriptionsController < ApplicationController
  before_action :authenticate_user!, except: [:pricing]
  before_action :set_subscription, only: [:show, :edit, :update, :destroy]

  def index
    @subscriptions = current_user.subscriptions
  end

  def show
  end

  def new
    @plan = params[:plan]&.gsub('_annual', '') # Remove _annual suffix if present
    @interval = params[:interval] || 'month'
    
    # Set price based on plan and interval
    @price = case @plan
             when 'basic'
               @interval.in?(['year', 'annual']) ? 99 : 9.99
             when 'pro'
               @interval.in?(['year', 'annual']) ? 199 : 19.99
             when 'enterprise'
               @interval.in?(['year', 'annual']) ? 499 : 49.99
             else
               0
             end

    # Set subscription options
    @subscription_options = {
      name: @plan&.titleize,
      price: @price,
      interval: @interval
    }
  end

  def create
    # Find the plan
    plan_name = params[:plan].to_s.gsub('_annual', '').titleize
    plan = Plan.find_by!(name: plan_name)
    
    begin
      # Configure Stripe API key
      Stripe.api_key = Rails.application.credentials.dig(:stripe, :test, :private_key)
      
      # Calculate the correct price based on interval
      price_amount = calculate_price(params[:plan], params[:interval])
      interval = params[:interval].in?(['year', 'annual']) ? 'year' : 'month'
      
      # Create a Stripe product if it doesn't exist
      product = Stripe::Product.create({
        name: "#{plan.name} (#{interval.capitalize})",
        metadata: {
          plan_id: plan.id,
          features: plan.features
        }
      })
      
      # Create a Stripe price for the plan
      price = Stripe::Price.create({
        unit_amount: (price_amount * 100).to_i,
        currency: 'usd',
        recurring: {
          interval: interval
        },
        product: product.id
      })
      
      # Create the subscription using Pay
      subscription = current_user.payment_processor.subscribe(
        name: plan.name,
        plan: price.id,
        metadata: {
          plan_id: plan.id
        }
      )
      
      redirect_to subscription_path(subscription.id), notice: "Successfully subscribed to #{plan.name} plan!"
    rescue => e
      redirect_to pricing_path, alert: "Failed to create subscription: #{e.message}"
    end
  end

  def edit
  end

  def update
    begin
      @subscription.swap(subscription_params[:plan])
      redirect_to subscription_path(@subscription), notice: "Subscription updated successfully."
    rescue => e
      redirect_to edit_subscription_path(@subscription), alert: "Failed to update subscription: #{e.message}"
    end
  end

  def destroy
    begin
      @subscription.cancel
      redirect_to subscriptions_path, notice: "Subscription cancelled successfully."
    rescue => e
      redirect_to subscription_path(@subscription), alert: "Failed to cancel subscription: #{e.message}"
    end
  end

  def success
    begin
      # Configure Stripe API key
      Stripe.api_key = Rails.application.credentials.dig(:stripe, :test, :private_key)
      
      # Get the checkout session with expanded subscription data
      session = Stripe::Checkout::Session.retrieve({
        id: params[:session_id],
        expand: ['subscription', 'subscription.default_payment_method']
      })
      
      # Get the subscription with expanded price and product data
      stripe_subscription = Stripe::Subscription.retrieve({
        id: session.subscription.id,
        expand: ['items.data.price.product']
      })
      
      # Get the price and product data
      price_data = stripe_subscription.items.data[0].price
      product_data = price_data.product
      
      # Create the subscription in our database
      @subscription = current_user.payment_processor.subscriptions.create!(
        name: product_data.name,
        processor_id: stripe_subscription.id,
        processor_plan: price_data.id,
        status: stripe_subscription.status,
        current_period_start: Time.at(stripe_subscription.current_period_start),
        current_period_end: Time.at(stripe_subscription.current_period_end),
        data: {
          stripe_id: stripe_subscription.id,
          stripe_status: stripe_subscription.status,
          stripe_price: price_data.id,
          stripe_product: product_data.id,
          amount: price_data.unit_amount,
          interval: price_data.recurring.interval
        }
      )
      
      redirect_to subscription_path(@subscription), notice: "Successfully subscribed!"
    rescue => e
      Rails.logger.error("Subscription Error: #{e.message}\n#{e.backtrace.join("\n")}")
      redirect_to pricing_path, alert: "Error processing subscription: #{e.message}"
    end
  end

  def pricing
    @plans = Plan.all.order(:price)
  end

  def billing
    # This action just renders the billing view
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
    @subscription = current_user.subscriptions.find(params[:id])
  end

  def subscription_params
    params.require(:subscription).permit(:plan, :interval, :payment_method_token)
  end

  def calculate_price(plan, interval)
    is_annual = interval.to_s.in?(['year', 'annual'])
    
    case plan.to_s
    when 'basic'
      is_annual ? 99 : 9.99
    when 'pro'
      is_annual ? 199 : 19.99
    when 'enterprise'
      is_annual ? 499 : 49.99
    else
      0
    end
  end
end 