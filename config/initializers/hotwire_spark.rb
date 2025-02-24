if Rails.env.development?
    # Enable Spark
    Rails.application.config.hotwire.spark.enabled = true

    # Configure HTML changes
    Rails.application.config.hotwire.spark.html_paths = %w[
        app/controllers
        app/components
        app/services
        app/validators
        app/helpers
        app/assets/images
        app/models
        app/views
        config/locales
        lib # Added custom path
    ]
    Rails.application.config.hotwire.spark.html_extensions = %w[rb erb png jpg jpeg webp svg yaml yml]
    Rails.application.config.hotwire.spark.html_reload_method = :morph # or :replace

    # Configure CSS changes
    Rails.application.config.hotwire.spark.css_paths = %w[app/assets/stylesheets]
    Rails.application.config.hotwire.spark.css_extensions = %w[css scss]

    # Configure Stimulus changes
    Rails.application.config.hotwire.spark.stimulus_paths = %w[app/javascript/controllers]
    Rails.application.config.hotwire.spark.stimulus_extensions = %w[js]

    # Enable logging in browser console
    Rails.application.config.hotwire.spark.logging = true
end