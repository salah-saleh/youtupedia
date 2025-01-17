# Provides caching functionality with dual-layer caching (Memcached + MongoDB/file)
# Implements atomic operations and handles cache misses gracefully
module Cacheable
  extend ActiveSupport::Concern

  class_methods do
    # Writes data to both Memcached and MongoDB atomically
    # Ensures data consistency across cache layers
    # write_cached will always write to MongoDB and Memcached independent of the result
    #
    # Logic flow:
    # 1. Write to MongoDB first (persistent storage)
    #    ├── Success: Continue to Memcached
    #    └── Failure: Return error result
    #
    # 2. Write to Memcached
    #    ├── Success: Return success result
    #    └── Failure: Return success (data is still in MongoDB)
    #
    # @param key [String] Cache key
    # @param data Data to cache (can be any object)
    # @param namespace [String, nil] Optional namespace for cache isolation
    # @param expires_in [Integer, nil] Cache TTL (nil for no expiration)
    # @return [Hash] Operation result with success status
    def write_cached(key, data, namespace: nil, expires_in: 1.second)
      return { success: false, error: "No data to cache" } unless data

      cache_namespace = namespace || default_cache_namespace
      memcache_key = "#{cache_namespace}_#{key}"

      begin
        # Write to MongoDB first
        cache = cache_service(cache_namespace)
        cache.write(key, data)

        # Then cache in Memcached
        Rails.cache.write(memcache_key, data, expires_in: expires_in)
        data
      rescue => e
        log_error "Cache write error", context: {
          error: e.message,
          backtrace: e.backtrace&.first(5),
          key: key,
          namespace: cache_namespace
        }
        { success: false, error: "Cache write error: #{e.message}" }
      end
    end

    # Fetches data from cache or generates it using provided block
    # Uses Memcached for fast access and MongoDB for persistent storage
    #
    # Logic flow:
    # 1. Check Memcached
    #    ├── Hit: Return cached data
    #    └── Miss: Continue to MongoDB
    #
    # 2. Check MongoDB
    #    ├── Hit AND valid result
    #    │   └── Return MongoDB data and cache in Memcached
    #    └── Miss OR invalid result
    #        └── Execute provided block
    #
    # 3. Process block result
    #    ├── Valid result
    #    │   ├── Write to MongoDB
    #    │   │   ├── Success: Return result and cache in Memcached
    #    │   │   └── Error: Return result without caching
    #    │   └── Return result
    #    ├── Hash but not successful
    #    │   └── Return result without caching
    #    └── Not a Hash
    #        └── Return result without caching
    #
    # @param key [String] Cache key
    # @param namespace [String, nil] Optional namespace for cache isolation
    # @param expires_in [Integer, nil] Cache TTL (nil for no expiration).
    #        1 second by default to avoid accidentally staling data
    # @param force_block_execution [Boolean] If true, force block execution even if Memcached is hit
    # @yield Block to generate data if not in cache
    # @return [Hash] Cached or generated data with success status
    #   @option [Boolean] :success Operation status
    #   @option [String] :error Error message if failed
    def fetch_cached(key, namespace: nil, expires_in: 1.second, force_block_execution: false)
      cache_namespace = namespace || default_cache_namespace
      memcache_key = "#{cache_namespace}_#{key}"

      if force_block_execution
        log_info "Force fetching cache", context: { key: memcache_key }
        Rails.cache.delete(memcache_key)
      end

      # Try to read directly from Memcached first
      if (cached = Rails.cache.read(memcache_key))
        log_info "Memcached hit", context: { key: memcache_key }
        return cached
      end

      # If not in Memcached, use fetch for atomic operation
      Rails.cache.fetch(memcache_key, expires_in: expires_in) do
        log_info "Memcached miss, checking MongoDB", context: { key: key, namespace: cache_namespace }

        result = nil
        unless force_block_execution
          cache = cache_service(cache_namespace)
          result = cache.read(key)
          log_info "Result from MongoDB", context: { result: result }
        end

        # Case 1: Valid MongoDB result - cache and return
        if result
          log_info "Valid result from MongoDB", context: { key: key }
          result  # Will be cached in Memcached

        # Case 2: Invalid or missing result - try block
        else
          log_info "Invalid or missing result, executing block", context: { key: key }
          result = yield if block_given?
          log_info "Block result", context: { result: result }

          # Case 2a: Valid block result - store in both caches
          if result
            log_info "Valid block result, storing in caches", context: { key: key }
            begin
              cache.write(key, result)
              result  # Will be cached in Memcached
            rescue => e
              log_error "MongoDB write failed", context: { error: e.message }
              return result  # Skip Memcached if MongoDB fails
            end

          # Case 2b: Invalid block result - return without caching
          else
            log_warn "Invalid block result, skipping cache", context: { key: key }
            return result  # Skip both caches
          end
        end
      end
    rescue => e
      log_error "Cache error", context: {
        error: e.message,
        backtrace: e.backtrace&.first(5),
        key: key,
        namespace: cache_namespace
      }
      { success: false, error: "Cache error: #{e.message}" }
    end

    private

    def cache_service(namespace = nil)
      Cache::CacheFactory.build(namespace || default_cache_namespace)
    end

    def default_cache_namespace
      name.demodulize.underscore.pluralize
    end
  end
end
