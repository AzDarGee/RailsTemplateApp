class Ai::Agent < ApplicationRecord
    has_many :conversations, class_name: "Ai::Conversation", dependent: :destroy
    belongs_to :user

    has_one_attached :avatar do |attachable|
        attachable.variant :thumb, resize_to_limit: [400, 400], preprocessed: true
    end

    before_validation do
        self.tools = [] if tools.blank?
    end

    def self.ransackable_attributes(auth_object = nil)
        ["id", "name", "description"]
    end

    def self.ransackable_associations(auth_object = nil)
        ["conversations", "user"]
    end
end
