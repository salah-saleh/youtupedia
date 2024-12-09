module Cache
  class FileCacheService < BaseCacheService
    def write(key, data)
      path = cache_path(key)
      Rails.logger.debug "CACHE [File] Writing data for '#{key}' to #{path}"
      ensure_directory_exists
      File.write(path, data.to_json)
      Rails.logger.debug "CACHE [File] Successfully wrote data to #{path}"
      data
    end

    def read(key)
      path = cache_path(key)
      Rails.logger.debug "CACHE [File] Reading '#{key}' from #{path}"
      data = JSON.parse(File.read(path), symbolize_names: true)
      Rails.logger.debug "CACHE [File] Successfully read data from #{path}"
      data
    rescue JSON::ParserError, Errno::ENOENT => e
      Rails.logger.error "CACHE [File] Error reading '#{key}': #{e.message}"
      nil
    end

    def exist?(key)
      path = cache_path(key)
      exists = File.exist?(path)
      Rails.logger.debug "CACHE [File] Checking existence of '#{key}': #{exists}"
      exists
    end

    def delete(key)
      path = cache_path(key)
      Rails.logger.debug "CACHE [File] Attempting to delete '#{key}'"
      if File.exist?(path)
        File.delete(path)
        Rails.logger.debug "CACHE [File] Successfully deleted #{path}"
      else
        Rails.logger.debug "CACHE [File] File not found for deletion: #{path}"
      end
    end

    private

    def cache_path(key)
      Rails.root.join("tmp", "cache", namespace, "#{key}.json")
    end

    def ensure_directory_exists
      dir = Rails.root.join("tmp", "cache", namespace)
      unless Dir.exist?(dir)
        Rails.logger.debug "CACHE [File] Creating directory: #{dir}"
        FileUtils.mkdir_p(dir)
      end
    end
  end
end
