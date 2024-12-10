module Cache
  class CacheFactory
    def self.build(namespace, type = default_type)
      case type.to_sym
      when :file
        Rails.logger.debug "[CacheFactory] Using FileCacheService for namespace: #{namespace}"
        FileCacheService.new(namespace)
      when :mongo
        Rails.logger.debug "[CacheFactory] Using MongoCacheService for namespace: #{namespace}"
        Rails.logger.debug "[CacheFactory] MongoDB URI: #{ENV['MONGODB_URI'].gsub(/:[^@]*@/, ':***@').first(20)}"
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
