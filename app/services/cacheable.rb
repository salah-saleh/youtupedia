# Provides caching functionality for services
module Cacheable
  extend ActiveSupport::Concern

  class_methods do
    def cache_service(namespace = nil)
      Cache::CacheFactory.build(namespace || default_cache_namespace)
    end

    def default_cache_namespace
      name.demodulize.underscore.pluralize
    end

    # Fetches data from cache or generates it using the provided block
    # Only caches successful results (where result[:success] is true)
    # Automatically clears failed results from cache
    #
    # @param key [String] Cache key
    # @param namespace [String, nil] Optional cache namespace
    # @yield Block to generate data if not in cache
    # @return [Hash] The cached or generated data
    def fetch_cached(key, namespace = nil)
      cache = cache_service(namespace)
      cache.fetch(key) { yield if block_given? }
    rescue => e
      # Handle cache-related errors
      log_error "Cache error", context: {
        error: e.message,
        backtrace: e.backtrace&.first(5),
        key: key,
        namespace: namespace || default_cache_namespace
      }
      { success: false, error: "Cache error: #{e.message}" }
    end
  end
end
