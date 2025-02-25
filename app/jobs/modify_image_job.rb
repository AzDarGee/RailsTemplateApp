class ModifyImageJob < ApplicationJob
  queue_as :default

  def perform(*args)
    if args[0].is_a?(User)
      user = args[0]
      # Modify image here
    end
  end
end
