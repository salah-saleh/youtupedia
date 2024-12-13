module Cache
  class BaseCacheService
    def initialize(namespace)
      @namespace = namespace
      log_debug "Initialized", context: { namespace: namespace }
    end

    def fetch(key, &block)
      log_debug "Attempting to fetch", key
      if exist?(key)
        log_debug "Cache hit", key
        data = read(key)
        log_debug "Retrieved data", key
        data
      elsif block_given?
        log_debug "Cache miss, generating data", key
        data = yield
        write(key, data)
        log_debug "Generated and cached data", key
        data
      end
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
