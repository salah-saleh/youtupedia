source "https://rubygems.org"
ruby "3.3.4"

# Bundle edge Rails instead: gem "rails", github: "rails/rails", branch: "main"
gem "rails", "~> 8.0.0"
# The modern asset pipeline for Rails [https://github.com/rails/propshaft]
gem "propshaft"
# Use sqlite3 as the database for Active Record
gem "sqlite3", ">= 2.1"
# Use the Puma web server [https://github.com/puma/puma]
gem "puma", ">= 5.0"
# Use JavaScript with ESM import maps [https://github.com/rails/importmap-rails]
gem "importmap-rails"
# Hotwire's SPA-like page accelerator [https://turbo.hotwired.dev]
gem "turbo-rails"
# Hotwire's modest JavaScript framework [https://stimulus.hotwired.dev]
gem "stimulus-rails"
# Build JSON APIs with ease [https://github.com/rails/jbuilder]
gem "jbuilder"

# Use Active Model has_secure_password [https://guides.rubyonrails.org/active_model_basics.html#securepassword]
gem "bcrypt", "~> 3.1.7"

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem "tzinfo-data", platforms: %i[ windows jruby ]

# Use the database-backed adapters for Rails.cache, Active Job, and Action Cable
gem "solid_cache"
gem "solid_queue"
gem "solid_cable"

# Reduces boot times through caching; required in config/boot.rb
gem "bootsnap", require: false

# Deploy this application anywhere as a Docker container [https://kamal-deploy.org]
gem "kamal", require: false

# Add HTTP asset caching/compression and X-Sendfile acceleration to Puma [https://github.com/basecamp/thruster/]
gem "thruster", require: false

# Use Active Storage variants [https://guides.rubyonrails.org/active_storage_overview.html#transforming-images]
# gem "image_processing", "~> 1.2"

group :development, :test do
  # See https://guides.rubyonrails.org/debugging_rails_applications.html#debugging-with-the-debug-gem
  gem "debug", platforms: %i[ mri windows ], require: "debug/prelude"

  # Static analysis for security vulnerabilities [https://brakemanscanner.org/]
  gem "brakeman", require: false

  # Omakase Ruby styling [https://github.com/rails/rubocop-rails-omakase/]
  gem "rubocop-rails-omakase", require: false
end

group :development do
  # Use console on exceptions pages [https://github.com/rails/web-console]
  gem "web-console"
  gem "foreman"
  # Email preview in development
  gem "letter_opener", "~> 1.10"

  # Ruby LSP and related gems
  gem "ruby-lsp", require: false
  gem "ruby-lsp-rails", require: false  # Add Rails-specific features

  # Static type checking
  gem "sorbet", "~> 0.5.11131"
  gem "sorbet-runtime", "~> 0.5.11131"
  gem "tapioca", "~> 0.11.9", require: false
end

group :test do
  # Use system testing [https://guides.rubyonrails.org/testing.html#system-testing]
  gem "capybara"
  gem "selenium-webdriver"
end

# Tailwind
gem "tailwindcss-rails", "~> 3.0"
# OpenAI
gem "ruby-openai"
# Google API
gem "google-apis-youtube_v3"
# Markdown
gem "redcarpet"
# Postgres
gem "pg"
# MongoDB
gem "mongoid"
# Memcached
gem "dalli"
# Load environment variables from .env file
gem "dotenv-rails", groups: [ :development, :test ]

# Email
gem "postmark-rails"

# Memory
gem "puma_worker_killer"

# Rate limiting
gem "rack-attack", "~> 6.7"

# Time synchronization
gem "net-ntp", require: false

# Sitemap
gem "sitemap_generator", "~> 6.3.0"

# Memory tracking
gem "get_process_mem"