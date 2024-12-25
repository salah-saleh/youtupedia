require_relative "boot"

require "rails/all"
require "mongoid"
require_relative "../lib/logging"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Y2si
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 8.0

    # Please, add to the `ignore` list any other `lib` subdirectories that do
    # not contain `.rb` files, or that should not be reloaded or eager loaded.
    # Common ones are `templates`, `generators`, or `middleware`, for example.
    config.autoload_lib(ignore: %w[assets tasks])

    # Silence asset logging
    config.assets.quiet = true

    # Add lib to the autoload paths
    config.autoload_paths << Rails.root.join("lib")


    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    # config.time_zone = "Central Time (US & Canada)"
    # config.eager_load_paths << Rails.root.join("extras")
    # config.autoload_paths += %W[#{config.root}/app/services/concerns]
    # config.autoload_paths += %W[#{config.root}/app/services]

    # Enable Tailwind CSS processing
    # By default, Rails uses a CSS compressor in production to minify CSS
    # However, this can interfere with Tailwind's own CSS processing
    # Setting it to nil ensures that Tailwind's JIT (Just-In-Time) compiler works correctly
    # Without this, you might get CSS compilation errors in production or missing styles
    config.assets.css_compressor = nil

    # Add middleware to set Current attributes
    config.middleware.use(
      Class.new do
        def initialize(app)
          @app = app
        end

        def call(env)
          request = ActionDispatch::Request.new(env)
          Current.set_attributes(request)
          @app.call(env)
        ensure
          Current.reset
        end
      end
    )
  end
end
