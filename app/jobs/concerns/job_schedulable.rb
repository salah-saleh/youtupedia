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
# "job_name:arg1:arg2:..."
#
# The status is automatically cleaned up after job completion or failure
# using an around_perform callback.
module JobSchedulable
  extend ActiveSupport::Concern

  class_methods do
    # Schedule a job with duplicate prevention
    # @param args [Array] Arguments to pass to the job
    # @return [Boolean] true if job was scheduled, false if already running
    def schedule(*args)
      job_key = "#{name.underscore}:#{args.join(':')}"
      if Rails.cache.exist?(job_key)
        log_info "Job already running: #{job_key}"
        return false
      end

      # Set a cache key to indicate job is processing
      # The 2-minutes expiry serves as a safety net for stalled jobs
      Rails.cache.write(job_key, true, expires_in: 2.minutes)
      perform_later(*args)
      true
    end

    private

    # Generate a unique key for a job based on its class name and arguments
    # @param args [Array] Job arguments
    # @return [String] Cache key
    def job_key_for(*args)
      "#{name.underscore}:#{args.join(':')}"
    end
  end

  # Get the cache key for the current job instance
  # @return [String] Cache key
  def job_key
    @job_key ||= self.class.send(:job_key_for, *arguments)
  end

  # Wrap job execution to ensure cleanup of cache key
  # This runs even if the job fails or raises an error
  def around_perform(*args)
    yield
  ensure
    Rails.cache.delete(job_key)
  end
end
