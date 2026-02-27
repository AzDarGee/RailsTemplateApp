class ToolCall < ApplicationRecord
  acts_as_tool_call

  def self.ransackable_attributes(auth_object = nil)
    [ "id", "name", "message", "result" ]
  end

  def self.ransackable_associations(auth_object = nil)
    # [ "agents", "conversations" ]
  end
end
