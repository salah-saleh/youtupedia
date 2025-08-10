require "active_support/core_ext/integer/time"
require "logger"

Rails.application.configure do
  # Settings specified here will take precedence over those in config/application.rb.

  # Code is not reloaded between requests.
  config.enable_reloading = false

  # Eager load code on boot for better performance and memory savings (ignored by Rake tasks).
  config.eager_load = true

  # Full error reports are disabled.
  config.consider_all_requests_local = false

  # Turn on fragment caching in view templates.
  config.action_controller.perform_caching = true

  # Cache assets for far-future expiry since they are all digest stamped.
  config.public_file_server.headers = { "cache-control" => "public, max-age=#{1.year.to_i}" }

  # Enable serving of images, stylesheets, and JavaScripts from an asset server.
  # config.asset_host = "http://assets.example.com"

  # Store uploaded files on the local file system (see config/storage.yml for options).
  config.active_storage.service = :local

  # Assume all access to the app is happening through a SSL-terminating reverse proxy.
  config.assume_ssl = true

  # Force all access to the app over SSL, use Strict-Transport-Security, and use secure cookies.
  config.force_ssl = true

  # Skip http-to-https redirect for the default health check endpoint.
  # config.ssl_options = { redirect: { exclude: ->(request) { request.path == "/up" } } }

  # Configure logging for production
  config.log_level =  ENV.fetch("RAILS_LOG_LEVEL", "debug")

  # Service-specific log levels
  Mongoid.logger.level = Logger::WARN
  Mongo::Logger.logger.level = Logger::ERROR
  Google::Apis.logger.level = Logger::Severity::WARN

  # Configure ActiveJob logging to be less verbose
  ActiveJob::Base.logger = Logger.new(STDOUT)
  ActiveJob::Base.logger.level = Logger::INFO

  # Set up console logger with custom formatter
  console_logger = ActiveSupport::Logger.new(STDOUT)
  console_logger.formatter = Logging::Formatter.new(
    colorize: false,
  )
  # console_logger = ActiveSupport::TaggedLogging.new(console_logger)
  console_logger.level = config.log_level

  Rails.logger = console_logger
  config.logger = console_logger

  # Prevent health checks from clogging up the logs
  config.silence_healthcheck_path = "/up"

    # Don't log any deprecations.
    config.active_support.report_deprecations = false

  # MemCachier configuration for production (multi-server setup)
  config.cache_store = :mem_cache_store,
    (ENV["MEMCACHIER_SERVERS"] || "").split(","),  # Array of server addresses for distributed caching
    {
      # Authentication (required for MemCachier)
      username: ENV["MEMCACHIER_USERNAME"],  # MemCachier credential
      password: ENV["MEMCACHIER_PASSWORD"],  # MemCachier credential

      # Memory Optimization Settings
      compress: true,              # Compress data to save memory
      expires_in: 1.day,          # Default TTL to prevent memory leaks
      
      # High Availability Settings
      failover: true,              # If a server is down, try the next one
      socket_timeout: 3.0,         # Seconds to wait for socket operations
      socket_failure_delay: 0.2,   # Seconds to wait before retrying a failed connection
      down_retry_delay: 60,        # Seconds to wait before retrying a down server

      # Connection Management - Based on dyno type
      # Basic: 5 threads
      # Standard-1X/2X: 10 threads
      # Performance-M/L: 20 threads
      pool_size:  5
    }

  # Replace the default in-process and non-durable queuing backend for Active Job.
  # config.active_job.queue_adapter = :resque

  # Enable delivery error reporting in production
  # config.action_mailer.raise_delivery_errors = true

  # # Set host to be used by links generated in mailer templates
  config.action_mailer.default_url_options = { host: "youtupedia.ai" }

  # # Configure delivery method
  config.action_mailer.delivery_method = :postmark
  config.action_mailer.postmark_settings = { api_token: ENV["POSTMARK_API_KEY"] }

  # # Enable SMTP/TLS when sending emails
  # config.action_mailer.smtp_settings = {
  #   domain: 'youtupedia.ai',
  #   address: 'smtp.sendgrid.net',
  #   port: 587,
  #   authentication: :plain,
  #   user_name: 'apikey',
  #   password: ENV['SENDGRID_API_KEY'],
  #   enable_starttls_auto: true
  # }

  # Enable locale fallbacks for I18n (makes lookups for any locale fall back to
  # the I18n.default_locale when a translation cannot be found).
  config.i18n.fallbacks = true

  # Do not dump schema after migrations.
  config.active_record.dump_schema_after_migration = false

  # Only use :id for inspections in production.
  config.active_record.attributes_for_inspect = [ :id ]

  # Only allow our main domains and specific subdomains in production
  config.hosts = [
    "youtupedia.ai",
    "www.youtupedia.ai",
    "youtupedia-290655871106.europe-west1.run.app",
    # Allow specific subdomains with more restrictive regex
    /^[\w-]+\.youtupedia\.ai$/,  # Only allows letters, numbers, hyphens
    # Skip DNS rebinding protection for health checks
    { exclude: ->(request) { request.path == "/up" } },
    "localhost",
    "0.0.0.0",
    IPAddr.new("0.0.0.0/0") # allows any IPv4 address
  ]

  # Skip DNS rebinding protection for the default health check endpoint.
  # config.host_authorization = { exclude: ->(request) { request.path == "/up" } }
end
