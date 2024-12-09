module Cache
  class CacheFactory
    def self.build(namespace, type = default_type)
      case type.to_sym
      when :file
        Rails.logger.info "Using FileCacheService for namespace: #{namespace}"
        FileCacheService.new(namespace)
      when :mongo
        Rails.logger.info "Using MongoCacheService for namespace: #{namespace}"
        MongoCacheService.new(namespace)
      else
        raise ArgumentError, "Unknown cache type: #{type}"
      end
    end

    def self.default_type
      Rails.configuration.x.cache_store || :mongo
    end
  end
end
