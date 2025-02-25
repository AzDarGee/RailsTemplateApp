class ModifyVideoJob < ApplicationJob
  queue_as :default

  def perform(*args)
    if args[0].is_a?(Video)
      video = args[0]
      # Modify video here
    end
  end
end
