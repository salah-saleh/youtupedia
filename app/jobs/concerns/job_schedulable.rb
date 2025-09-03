# JobSchedulable provides duplicate prevention for ActiveJob jobs.
# It ensures that only one instance of a job with specific arguments can run at a time.
#
# Usage:
#   class MyJob < ApplicationJob
#     def perform(arg1, arg2)
#       # your job code
#     end
#   end
#
#   # Schedule the job:
#   if MyJob.schedule("value1", "value2")
#     # Job was scheduled successfully
#   else
#     # Job with these arguments is already running
#   end
#
# The job status is tracked using Rails.cache with a key format of:
# "job_name:sha256_hash_of_args"
#
# The status is automatically cleaned up after job completion or failure
# using an around_perform callback.
require 'digest'

module JobSchedulable
  extend ActiveSupport::Concern

  included do
    # Register the around_perform callback when the module is included
    around_perform :cleanup_job_cache
  end

  class_methods do
    # Schedule a job with duplicate prevention
    # @param args [Array] Arguments to pass to the job
    # @return [Boolean] true if job was scheduled, false if already running
    def schedule(*args)
      job_key = build_job_cache_key(*args)
      if Rails.cache.exist?(job_key)
        log_info "Job already running: #{job_key}"
        return false
      end
      
      # Set a cache key to indicate job is processing
      Rails.cache.write(job_key, true)
      perform_later(*args)
      true
    end

    # Manually clear a stuck job cache key
    # @param args [Array] Arguments that were passed to the job
    # @return [Boolean] true if key was deleted, false if it didn't exist
    def clear_job_cache(*args)
      job_key = build_job_cache_key(*args)
      deleted = Rails.cache.delete(job_key)
      log_info "Manually cleared job cache key: #{job_key}, deleted: #{deleted}"
      deleted
    end

    private

    # Build a cache key using a hash of arguments to handle large data efficiently
    # @param args [Array] Job arguments
    # @return [String] Cache key
    def build_job_cache_key(*args)
      # Use SHA256 hash of arguments to create a consistent, short cache key
      # This prevents issues with large arguments like base64 audio content
      args_hash = Digest::SHA256.hexdigest(args.to_json)
      "#{name.underscore}:#{args_hash}"
    end

    # Generate a unique key for a job based on its class name and arguments
    # @param args [Array] Job arguments
    # @return [String] Cache key
    def job_key_for(*args)
      build_job_cache_key(*args)
    end
  end

  # Get the cache key for the current job instance
  # @return [String] Cache key
  def job_key
    @job_key ||= self.class.send(:job_key_for, *arguments)
  end

  # Wrap job execution to ensure cleanup of cache key
  # This runs even if the job fails or raises an error
  def cleanup_job_cache
    log_info "Starting job with cache key: #{job_key}"
    begin
      yield
    ensure
      # Always clean up the cache key, regardless of success/failure
      deleted = Rails.cache.delete(job_key)
      log_info "Cleaned up job cache key: #{job_key}, deleted: #{deleted}"
    end
  end
end
