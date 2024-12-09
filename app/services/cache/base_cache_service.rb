module Cache
  class BaseCacheService
    def initialize(namespace)
      @namespace = namespace
      Rails.logger.debug "CACHE [#{self.class.name}] Initialized for namespace '#{namespace}'"
    end

    def fetch(key, &block)
      Rails.logger.debug "CACHE [#{self.class.name}] Attempting to fetch '#{key}'"
      if exist?(key)
        Rails.logger.debug "CACHE [#{self.class.name}] Cache hit for '#{key}'"
        data = read(key)
        Rails.logger.debug "CACHE [#{self.class.name}] Retrieved data for '#{key}'"
        data
      elsif block_given?
        Rails.logger.debug "CACHE [#{self.class.name}] Cache miss for '#{key}', generating data..."
        data = yield
        write(key, data)
        Rails.logger.debug "CACHE [#{self.class.name}] Generated and cached data for '#{key}'"
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
