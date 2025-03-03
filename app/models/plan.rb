class Plan < ApplicationRecord
  validates :name, presence: true
  validates :price, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :description, presence: true
  validates :features, presence: true
  
  # If you want to store features as an array in PostgreSQL
  # serialize :features, Array if you're using MySQL or SQLite
end 