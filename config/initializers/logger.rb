require "active_support/logger"
require "active_support/broadcast_logger"

# # Create loggers
# stdout_logger = ActiveSupport::Logger.new(STDOUT)
# file_logger = ActiveSupport::Logger.new(Rails.root.join("log/#{Rails.env}.log"))

# # Set formatters
# formatter = Logger::Formatter.new
# stdout_logger.formatter = formatter
# file_logger.formatter = formatter

# # Combine loggers using BroadcastLogger
# combined_logger = ActiveSupport::BroadcastLogger.new(stdout_logger, file_logger)

# # Set log level
# combined_logger.level = Rails.env.production? ? :info : :debug

# # Add tagging
# Rails.logger = ActiveSupport::TaggedLogging.new(combined_logger)

# Rails.logger.datetime_format = "%Y-%m-%d %H:%M:%S"

# # Ensure Rails uses our logger
# Rails.application.config.logger = Rails.logger
