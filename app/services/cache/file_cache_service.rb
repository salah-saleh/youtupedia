module Cache
  class FileCacheService
    def initialize(namespace)
      @namespace = namespace
      @cache_dir = Rails.root.join("tmp", "cache", namespace)
      FileUtils.mkdir_p(@cache_dir)
      Rails.logger.debug "CACHE: Initialized FileCacheService for namespace '#{namespace}' at #{@cache_dir}"
    end

    def fetch(key, &block)
      Rails.logger.debug "CACHE: Attempting to fetch '#{key}' from namespace '#{@namespace}'"
      path = cache_path(key)

      if exist?(key)
        Rails.logger.debug "CACHE: Cache hit for '#{key}' in namespace '#{@namespace}'"
        data = read(key)
        Rails.logger.debug "CACHE: Retrieved data for '#{key}': #{data.inspect.first(100)}"
        data
      elsif block_given?
        Rails.logger.debug "CACHE: Cache miss for '#{key}', generating data..."
        data = yield
        write(key, data)
        Rails.logger.debug "CACHE: Generated and cached data for '#{key}': #{data.inspect.first(100)}"
        data
      else
        Rails.logger.debug "CACHE: Cache miss for '#{key}' and no block given"
        nil
      end
    end

    def write(key, data)
      Rails.logger.debug "CACHE: Writing data for '#{key}' to namespace '#{@namespace}'"
      path = cache_path(key)
      File.write(path, data.to_json)
      Rails.logger.debug "CACHE: Successfully wrote data to #{path}"
      data
    end

    def read(key)
      Rails.logger.debug "CACHE: Reading '#{key}' from namespace '#{@namespace}'"
      path = cache_path(key)
      data = JSON.parse(File.read(path), symbolize_names: true)
      Rails.logger.debug "CACHE: Successfully read data from #{path}"
      data
    rescue JSON::ParserError => e
      Rails.logger.error "CACHE: JSON parse error for '#{key}': #{e.message}"
      nil
    rescue Errno::ENOENT => e
      Rails.logger.error "CACHE: File not found for '#{key}': #{e.message}"
      nil
    end

    def exist?(key)
      path = cache_path(key)
      exists = File.exist?(path)
      Rails.logger.debug "CACHE: Checking existence of '#{key}' in namespace '#{@namespace}': #{exists}"
      exists
    end

    def delete(key)
      Rails.logger.debug "CACHE: Deleting '#{key}' from namespace '#{@namespace}'"
      path = cache_path(key)
      if File.exist?(path)
        File.delete(path)
        Rails.logger.debug "CACHE: Successfully deleted #{path}"
      else
        Rails.logger.debug "CACHE: File not found for deletion: #{path}"
      end
    end

    private

    def cache_path(key)
      Rails.root.join(@cache_dir, "#{key}.json")
    end
  end
end
