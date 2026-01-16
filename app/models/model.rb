class Model < ApplicationRecord
  acts_as_model

  def self.ransackable_attributes(auth_object = nil)
    [ "id", "name", "family", "provider" ]
  end

  def self.ransackable_associations(auth_object = nil)
    # [ "agents", "conversations" ]
  end
end
