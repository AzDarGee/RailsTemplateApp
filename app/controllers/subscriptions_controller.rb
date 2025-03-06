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
      
      # Create a checkout session for the subscription
      session = Stripe::Checkout::Session.create({
        payment_method_types: ['card'],
        customer: current_user.payment_processor.processor_id,
        line_items: [{
          price: price.id,
          quantity: 1,
        }],
        mode: 'subscription',
        success_url: success_subscriptions_url + "?session_id={CHECKOUT_SESSION_ID}",
        cancel_url: pricing_url,
        metadata: {
          plan_id: plan.id,
          plan_name: plan.name,
          interval: interval,
          user_id: current_user.id
        }
      })
      
      # Redirect to Stripe Checkout
      redirect_to session.url, allow_other_host: true
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
      
      # Get the checkout session
      session = Stripe::Checkout::Session.retrieve({
        id: params[:session_id]
      })
      
      # Get the subscription with expanded price and product data
      stripe_subscription = Stripe::Subscription.retrieve({
        id: session.subscription,
        expand: ['items.data.price.product', 'default_payment_method']
      })
      
      # Get the price and product data
      price_data = stripe_subscription.items.data[0].price
      product_data = price_data.product
      
      # Check if subscription already exists
      existing_subscription = current_user.payment_processor.subscriptions.find_by(processor_id: stripe_subscription.id)
      
      if existing_subscription
        # Update existing subscription
        existing_subscription.update!(
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
        @subscription = existing_subscription
      else
        # Deactivate all other active subscriptions
        current_user.payment_processor.subscriptions.active.where.not(processor_id: stripe_subscription.id).each do |sub|
          begin
            # Cancel the subscription in Stripe
            Stripe::Subscription.update(
              sub.processor_id,
              { cancel_at_period_end: true }
            )
            
            # Mark as canceled in our database
            sub.update(status: 'canceled', ends_at: Time.at(sub.current_period_end))
          rescue => e
            Rails.logger.error("Failed to cancel subscription #{sub.id}: #{e.message}")
          end
        end
        
        # Create new subscription
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
      end
      
      redirect_to subscription_path(@subscription), notice: "Successfully subscribed to #{product_data.name}!"
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