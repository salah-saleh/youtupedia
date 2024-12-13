class BaseAsyncService
  def self.process_async(key, *args)
    AsyncJobProcessor.schedule(self.name, key, *args)
  end

  def self.process(key, *args)
    cache_service = Cache::CacheFactory.build(cache_namespace)

    cache_service.fetch(key) do
      log_debug "Processing", key
      result = new.perform(*args)
      log_debug "Completed processing", key
      result
    end
  end

  def self.cache_namespace
    name.demodulize.underscore.pluralize
  end

  def perform(*args)
    raise NotImplementedError
  end
end
