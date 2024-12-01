class BaseAsyncService
  def self.process_async(key, *args)
    AsyncJobProcessor.schedule(self.name, key, *args)
  end

  def self.process(key, *args)
    cache_service = Cache::FileCacheService.new(cache_namespace)

    cache_service.fetch(key) do
      Rails.logger.debug "#{self.name}: Processing #{key} with args: #{args.inspect}"
      result = new.perform(*args)
      Rails.logger.debug "#{self.name}: Completed processing #{key} with result: #{result.inspect.first(100)}"
      result
    end
  end

  def self.cache_namespace
    self.name.demodulize.underscore.pluralize
  end

  # To be implemented by child classes
  def perform(*args)
    raise NotImplementedError
  end
end
