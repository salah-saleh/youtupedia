module Cache
  class BaseCacheService
    def initialize(namespace)
      @namespace = namespace
      log_info "Initialized", context: { namespace: namespace }
    end

    # Fetches data from cache or generates it using the provided block
    # Only caches successful results (where result[:success] is true)
    # Automatically clears failed results from cache
    #
    # @param key [String] Cache key
    # @yield Block to generate data if not in cache
    # @return [Hash] The cached or generated data
    def fetch(key, &block)
      log_info "Attempting to fetch", key

      # Try to get from cache first
      if exist?(key)
        log_info "Cache hit", key
        cached_data = read(key)

        # If cached data represents a failure, clear it and try again
        if cached_data.is_a?(Hash) && cached_data[:success] == false
          log_info "Found failed result in cache, clearing", context: {
            key: key,
            error: cached_data[:error]
          }
          delete(key)
        else
          log_info "Retrieved data", key
          return cached_data
        end
      end

      return unless block_given?

      # Execute the block to get fresh data
      log_info "Cache miss", key
      result = yield

      # Only cache successful results
      if result.is_a?(Hash) && result[:success]
        log_info "Caching successful result", context: { key: key }
        write(key, result)
      elsif result.is_a?(Hash) && result[:error]
        log_info "Not caching failed result", context: {
          key: key,
          error: result[:error]
        }
      else
        log_info "Nothing to cache", context: {
          key: key,
          result: result
        }
      end

      result
    end

    def write(key, data)
      raise NotImplementedError
    end

    def read(key)
      raise NotImplementedError
    end

    def exist?(key)
      raise NotImplementedError
    end

    def delete(key)
      raise NotImplementedError
    end

    protected

    attr_reader :namespace
  end
end
