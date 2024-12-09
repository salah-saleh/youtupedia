namespace :cache do
  desc "Migrate data from file cache to MongoDB"
  task migrate_to_mongo: :environment do
    def migrate_namespace(namespace)
      file_cache = Cache::FileCacheService.new(namespace)
      mongo_cache = Cache::MongoCacheService.new(namespace)

      # Get all files in the cache directory
      cache_dir = Rails.root.join("tmp", "cache", namespace)

      # Skip if directory doesn't exist
      unless Dir.exist?(cache_dir)
        puts "Skipping #{namespace} - directory doesn't exist"
        return
      end

      # Ensure directory exists for file cache
      FileUtils.mkdir_p(cache_dir)

      Dir.glob("#{cache_dir}/*.json").each do |file|
        key = File.basename(file, ".json")
        begin
          data = JSON.parse(File.read(file), symbolize_names: true)
          mongo_cache.write(key, data)
          puts "Migrated #{namespace}/#{key}"
        rescue => e
          puts "Error migrating #{namespace}/#{key}: #{e.message}"
          puts e.backtrace.first
        end
      end
    end

    # List of namespaces to migrate
    namespaces = [
      "channels",
      "channel_videos",
      "transcripts/segmented",
      "transcripts/full",
      "chat_threads",
      "user_data",
      Chat::ChatGptService.cache_namespace
    ]

    namespaces.each do |namespace|
      puts "Migrating namespace: #{namespace}"
      # Ensure parent directories exist for nested namespaces
      if namespace.include?("/")
        FileUtils.mkdir_p(Rails.root.join("tmp", "cache", namespace.split("/").first))
      end
      migrate_namespace(namespace)
    end
  end
end
