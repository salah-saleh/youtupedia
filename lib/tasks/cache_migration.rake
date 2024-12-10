namespace :cache do
  desc "Migrate data from file cache to MongoDB"
  task migrate_to_mongo: :environment do
    def migrate_namespace(namespace)
      mongo_cache = Cache::MongoCacheService.new(namespace)

      cache_dir = Rails.root.join("tmp", "cache", namespace)

      unless Dir.exist?(cache_dir)
        puts "Skipping #{namespace} - directory doesn't exist"
        return
      end

      puts "Migrating namespace: #{namespace}"
      migrated = 0
      errors = 0

      Dir.glob("#{cache_dir}/*.json").each do |file|
        key = File.basename(file, ".json")
        begin
          puts "  Processing #{key}..."
          data = JSON.parse(File.read(file), symbolize_names: true)
          mongo_cache.write(key, data)
          migrated += 1
          puts "  ✓ Migrated #{key}"
        rescue => e
          errors += 1
          puts "  ✗ Error with #{key}: #{e.message}"
        end
      end

      puts "Completed #{namespace}: #{migrated} migrated, #{errors} errors"
    end

    namespaces = [
      "channels",
      "channel_videos",
      "transcripts/segmented",
      "transcripts/full",
      "chat_threads",
      "user_data",
      Chat::ChatGptService.cache_namespace
    ]

    puts "Starting migration to MongoDB (#{ENV['MONGODB_URI'].split('@').last})"
    namespaces.each { |ns| migrate_namespace(ns) }
  end
end
