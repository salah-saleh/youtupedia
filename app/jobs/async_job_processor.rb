# Handles background processing of async tasks for services using AsyncProcessable
#
# The AsyncJobProcessor works together with AsyncProcessable to provide
# background job processing with caching. The flow is:
#
# 1. Service starts async processing:
#    MyService.start_async("unique_key", arg1, arg2)
#
# 2. AsyncJobProcessor checks if result exists:
#    - If exists: does nothing (prevents duplicate processing)
#    - If not: schedules background job
#
# 3. Background job runs:
#    - Creates new service instance
#    - Calls perform(args) on the instance
#    - Caches the result under the key
#
# 4. Service can check result:
#    result = MyService.fetch_result("unique_key")
#
# Example:
#   class MyService
#     include Concerns::AsyncProcessable
#
#     def perform(arg1, arg2)
#       { success: true, data: process_data(arg1, arg2) }
#     end
#   end
class AsyncJobProcessor < ApplicationJob
  queue_as :default

  # Schedules a background job for async processing
  # Only schedules if no result exists for the given key
  #
  # @param service_class_name [String] Name of the service class (e.g., "Ai::ChatGptService")
  # @param key [String] Unique key to identify this job/result
  # @param args [Array] Arguments to pass to the service's perform method
  # @return [void]
  def self.schedule(service_class_name, key, *args)
    # Convert to consistent format
    namespace = service_class_name.demodulize.underscore.pluralize
    cache_service = Cache::CacheFactory.build(namespace)
    return if cache_service.exist?(key)

    log_info "Scheduling job", context: { service: service_class_name, key: key }
    set(wait: 1.second).perform_later(service_class_name, key, *args)
  end

  # Executes the async task and caches its result
  # Called by ActiveJob when processing the background job
  #
  # @param service_class_name [String] Name of the service class to instantiate
  # @param key [String] Key to store the result under
  # @param args [Array] Arguments to pass to perform
  def perform(service_class_name, key, *args)
    log_info "Processing job", context: { service: service_class_name, key: key }

    # Create service instance and process task
    service_class = service_class_name.constantize
    result = service_class.new.process_task(*args)

    # Use service's namespace
    namespace = service_class.name.demodulize.underscore.pluralize
    cache_service = Cache::CacheFactory.build(namespace)

    log_info "Caching result", context: {
      service: service_class_name,
      key: key,
      namespace: namespace,
      success: result[:success]
    }

    cache_service.write(key, result)
  end
end
