class ApplicationJob < ActiveJob::Base
  include JobSchedulable

  # Automatically retry jobs that encountered a deadlock
  # This is useful when multiple jobs try to access the same records simultaneously
  # Rails will automatically retry the job when a deadlock occurs
  retry_on ActiveRecord::Deadlocked

  # Most jobs are safe to ignore if the underlying records are no longer available
  # For example, if a job tries to process a record that was deleted
  # Instead of failing, the job will be discarded
  discard_on ActiveJob::DeserializationError
end
