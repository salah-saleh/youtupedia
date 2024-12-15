# Provides async processing capabilities for services.
# This concern enables services to:
# 1. Start async jobs that will process tasks in the background
# 2. Check results from those async jobs
#
# Usage example:
#   class MyService < BaseService
#     include Concerns::AsyncProcessable
#
#     def process_task(arg1, arg2)
#       # Do the actual processing work
#       { success: true, data: "processed" }
#     end
#   end
#
#   # Start async processing:
#   MyService.start_async("unique_key", arg1, arg2)
#
#   # Later, check if processing is done:
#   result = MyService.fetch_result("unique_key")
#   if result
#     # Process completed, use result
#   else
#     # Still processing
#   end
module AsyncProcessable
  extend ActiveSupport::Concern

  class_methods do
    # Starts asynchronous processing by scheduling a background job
    # Only schedules if no result exists for this key
    #
    # @param key [String] Unique identifier for this job/result
    # @param args [Array] Arguments to pass to the perform method
    # @return [void]
    def start_async(key, *args)
      AsyncJobProcessor.schedule(name, key, *args)
      log_debug "Started async job", context: { key: key, service: name }
    end

    # Checks if async processing is complete and returns the result
    # Does not trigger processing, only checks for existing results
    #
    # @param key [String] Unique identifier for this job/result
    # @return [Hash, nil] The result hash if processing is complete, nil if still processing
    def fetch_result(key)
      cache_service = Cache::CacheFactory.build(default_cache_namespace)
      cache_service.exist?(key) ? cache_service.read(key) : nil
    end

    # Returns the cache namespace for this service
    # @return [String] The cache namespace
    def default_cache_namespace
      name.demodulize.underscore.pluralize
    end
  end

  # Must be implemented by including class
  # This method does the actual task processing
  #
  # @param args [Array] Arguments passed from the async job
  # @return [Hash] Must return a hash with at least a :success key
  def process_task(*args)
    raise NotImplementedError
  end
end
