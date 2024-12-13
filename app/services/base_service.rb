class BaseService
  def self.cache_service(namespace)
    Cache::CacheFactory.build(namespace)
  end

  def self.handle_error(error, prefix = "Error")
    log_error "#{prefix}: #{error.message}"
    log_error "Full error details", error.full_message
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
