require "sitemap_generator"

# if moved from heroku, we need to implement a cron and a worker
# https://devcenter.heroku.com/articles/scheduler
# to see the contents of the sitemap, run `RAILS_ENV=development bundle exec rake sitemap:generate`
# gunzip -c public/sitemap.xml.gz | xmllint --format - | cat
namespace :sitemap do
  desc "Generate the sitemap and ping search engines"
  task update: :environment do
    begin
      # Capture the start time
      start_time = Time.current
      puts "Starting sitemap generation at #{start_time}"

      # Generate the sitemap
      SitemapGenerator::Interpreter.run(config_file: Rails.root.join("config/sitemap.rb"))
      
      # Ping search engines in production only
      if Rails.env.production?
        puts "Pinging search engines..."
        SitemapGenerator::Sitemap.ping_search_engines
        puts "Search engines have been notified"
      end

      # Log completion time and duration
      end_time = Time.current
      duration = (end_time - start_time).round(2)
      puts "Sitemap generation completed at #{end_time} (took #{duration} seconds)"

      # Verify the sitemap exists
      sitemap_path = Rails.root.join("public/sitemap.xml.gz")
      if File.exist?(sitemap_path)
        puts "Sitemap generated successfully at #{sitemap_path}"
        puts "Filesize: #{(File.size(sitemap_path).to_f / 1024).round(2)}KB"
      else
        raise "Sitemap file not found at #{sitemap_path}"
      end

    rescue StandardError => e
      puts "Error generating sitemap: #{e.message}"
      puts e.backtrace.join("\n") if Rails.env.development?
      raise e if Rails.env.development? # Re-raise in development
    end
  end

  # Keep these as separate tasks for backward compatibility
  desc "Generate the sitemap"
  task generate: :update

  desc "Generate and ping search engines"
  task ping: :update
end 