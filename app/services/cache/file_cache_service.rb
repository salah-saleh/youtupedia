class Cache::FileCacheService
  def initialize(cache_dir)
    @cache_dir = Rails.root.join("tmp", cache_dir)
    FileUtils.mkdir_p(@cache_dir) unless Dir.exist?(@cache_dir)
  end

  def fetch(key, version: nil)
    cache_file = cache_path(key, version)

    if File.exist?(cache_file)
      Rails.logger.info("Cache hit: Loading from #{cache_file}")
      return JSON.parse(File.read(cache_file), symbolize_names: true)
    end

    Rails.logger.info("Cache miss: Fetching fresh data for #{key}")
    result = yield # Execute the block (API call)
    write(key, result, version: version)
    result
  rescue => e
    Rails.logger.error "Cache error for #{key}: #{e.message}"
    yield # On cache error, fallback to fresh data
  end

  def write(key, data, version: nil)
    cache_file = cache_path(key, version)
    Rails.logger.info("Writing cache to #{cache_file}")
    File.write(cache_file, JSON.pretty_generate(data))
    data
  end

  private

  def cache_path(key, version)
    filename = version ? "#{key}_#{version}.json" : "#{key}.json"
    @cache_dir.join(filename)
  end
end
