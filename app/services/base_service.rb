class BaseService
  def self.cache_service(namespace)
    Cache::FileCacheService.new(namespace)
  end

  def self.handle_error(error, prefix = "Error")
    Rails.logger.error "#{prefix}: #{error.message}"
    Rails.logger.error "Full error details: #{error.full_message}"
    { success: false, error: "#{prefix}: #{error.message}" }
  end

  def self.fetch_cached(key, namespace = nil)
    cache = cache_service(namespace || default_cache_namespace)
    cache.fetch(key) { yield if block_given? }
  rescue => e
    handle_error(e)
  end

  private

  def self.default_cache_namespace
    name.demodulize.underscore.pluralize
  end
end
