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

# Create a custom formatter that handles async operations
class CustomFormatter < Logger::Formatter
    def call(severity, datetime, progname, msg)
        formatted_datetime = datetime.strftime('%Y-%m-%d %H:%M:%S')
        msg = msg.is_a?(Exception) ? "#{msg.message} (#{msg.class})" : msg.to_s
        "[#{formatted_datetime}] #{severity.ljust(5)} | #{msg}\n"
    rescue => e
        "[#{formatted_datetime}] ERROR | Logger error: #{e.message}\n"
    end
end

# Create loggers with error handling
begin
    # STDOUT logger
    stdout_logger = ActiveSupport::Logger.new(STDOUT).tap do |logger|
        logger.formatter = CustomFormatter.new
        logger.level = Rails.env.production? ? Logger::INFO : Logger::DEBUG
    end

    # File logger
    log_file = Rails.root.join("log/#{Rails.env}.log")
    file_logger = ActiveSupport::Logger.new(log_file).tap do |logger|
        logger.formatter = CustomFormatter.new
        logger.level = Rails.env.production? ? Logger::INFO : Logger::DEBUG
    end

    # Broadcast logger with error handling
    broadcast_logger = ActiveSupport::BroadcastLogger.new(stdout_logger, file_logger)
    broadcast_logger.level = Rails.env.production? ? Logger::INFO : Logger::DEBUG

    # Tagged logging wrapper
    tagged_logger = ActiveSupport::TaggedLogging.new(broadcast_logger)

    # Set Rails logger
    Rails.logger = tagged_logger
    Rails.application.config.logger = tagged_logger

    puts "Logger initialization complete!"
rescue => e
    puts "Logger initialization failed: #{e.message}"
    raise
end

# Add Turbo stream error handling
Rails.application.config.after_initialize do
    ActiveSupport::Notifications.subscribe("turbo_stream.error") do |*args|
        error = args.last
        Rails.logger.error "Turbo Stream Error: #{error.message}"
    end
end