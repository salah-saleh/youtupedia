class AsyncJobProcessor < ApplicationJob
  queue_as :default

  def self.schedule(service_class_name, key, *args)
    cache_service = Cache::FileCacheService.new(service_class_name.demodulize.underscore.pluralize)
    return if cache_service.exist?(key)

    Rails.logger.debug "ASYNC_JOB: Scheduling #{service_class_name} for key #{key} with args: #{args.inspect}"
    set(wait: 1.second).perform_later(service_class_name, key, *args)
  end

  def perform(service_class_name, key, *args)
    Rails.logger.debug "ASYNC_JOB: Processing #{service_class_name} for key #{key}"
    service_class = service_class_name.constantize
    service_class.process(key, *args)
  end
end
