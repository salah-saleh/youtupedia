module Cache
  class FileCacheService < BaseCacheService
    def write(key, data)
      path = cache_path(key)
      log_debug "Writing data", key, context: { path: path }
      ensure_directory_exists
      File.write(path, data.to_json)
      log_debug "Successfully wrote data", key, context: { path: path }
      data
    end

    def read(key)
      path = cache_path(key)
      log_debug "Reading", key, context: { path: path }
      data = JSON.parse(File.read(path), symbolize_names: true)
      log_debug "Successfully read data", key, context: { path: path }
      data
    rescue JSON::ParserError, Errno::ENOENT => e
      log_error "Error reading", key, context: { path: path, error: e.message }
      nil
    end

    def exist?(key)
      path = cache_path(key)
      exists = File.exist?(path)
      log_debug "Checking existence", key, context: { path: path, exists: exists }
      exists
    end

    def delete(key)
      path = cache_path(key)
      log_debug "Attempting to delete", key, context: { path: path }
      if File.exist?(path)
        File.delete(path)
        log_debug "Successfully deleted", key, context: { path: path }
      else
        log_debug "File not found for deletion", key, context: { path: path }
      end
    end

    private

    def cache_path(key)
      Rails.root.join("tmp", "cache", namespace, "#{key}.json")
    end

    def ensure_directory_exists
      dir = Rails.root.join("tmp", "cache", namespace)
      unless Dir.exist?(dir)
        log_debug "Creating directory", context: { path: dir }
        FileUtils.mkdir_p(dir)
      end
    end
  end
end
