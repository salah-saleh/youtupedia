class AsyncJobProcessor < ApplicationJob
  queue_as :default

  def self.schedule(service_class_name, key, *args)
    namespace = service_class_name.demodulize.underscore.pluralize
    cache_service = Cache::CacheFactory.build(namespace)
    return if cache_service.exist?(key)

    log_debug "Scheduling job", context: { service: service_class_name, key: key }
    set(wait: 1.second).perform_later(service_class_name, key, *args)
  end

  def perform(service_class_name, key, *args)
    log_debug "Processing job", context: { service: service_class_name, key: key }
    service_class = service_class_name.constantize
    service_class.process(key, *args)
  end
end
