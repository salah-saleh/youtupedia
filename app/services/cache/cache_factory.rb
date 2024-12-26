module Cache
  class CacheFactory
    def self.build(namespace, type = default_type)
      case type.to_sym
      when :file
        log_info "Using FileCacheService", context: { namespace: namespace }
        FileCacheService.new(namespace)
      when :mongo
        log_info "Using MongoCacheService", context: {
          namespace: namespace,
          uri: ENV["MONGODB_URI"].gsub(/:[^@]*@/, ":***@").first(20)
        }
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
