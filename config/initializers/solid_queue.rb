Rails.application.config.solid_queue.configure do |config|
    config.silence_polling = true
    
    # Configure the worker pool
    config.worker_pool = {
      size: 5  # Sets the worker pool size
    }
  end