class Plan < ApplicationRecord
  INTERVALS = %w[day week month year].freeze

  validates :key, presence: true, uniqueness: true
  validates :name, presence: true
  validates :interval, presence: true, inclusion: { in: INTERVALS }
  validates :price_cents, numericality: { only_integer: true, greater_than_or_equal_to: 0 }, allow_nil: true

  scope :active, -> { where(active: true) }
  scope :ordered, -> { order(position: :asc, price_cents: :asc, name: :asc) }

  # Safe accessor for Stripe Price ID, prioritizing ENV over credentials.
  def stripe_price_id
    ENV[self.env_price_key].presence || self.credentials_price_id
  end

  private

  def credentials_price_id
    # Access Rails credentials defensively to avoid raising when no master key is set.
    begin
      Rails.application.credentials.dig(:stripe, :prices, self.key.to_s)
    rescue => _e
      nil
    end
  end
end
