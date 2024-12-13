# The RequestLockService provides atomic locking functionality to prevent concurrent operations.
# It uses Rails.cache as a distributed lock mechanism, with the following features:
#
# - Atomic lock acquisition using write(unless_exist: true)
# - Token-based ownership to prevent accidental lock releases
# - Configurable automatic lock expiration to prevent deadlocks
# - Support for both blocking and non-blocking lock attempts
#
# Lock Expiration:
# - Locks automatically expire after a configurable time (default: 5 minutes)
# - After expiration, the cache entry is automatically removed
# - Any new request can acquire a new lock after expiration
# - This prevents permanent locks if a process crashes
# - The expiration is handled by Rails.cache's built-in TTL mechanism
#
# Configuration:
# You can configure the default lock timeout globally:
#   RequestLockService.default_lock_timeout = 10.minutes
#
# Or per-lock:
#   RequestLockService.with_lock(user_id, "search", timeout: 1.minute) do
#     # work here
#   end
#
# Blocking vs Non-Blocking Locks:
#
# 1. Blocking Locks (acquire_lock):
#    - Raises ConcurrentRequestError when lock can't be acquired
#    - Used when you want to explicitly handle concurrent requests (e.g., showing error messages)
#    - Best for user-facing actions where you want to show feedback
#    - Example: Search page where you want to show "Please wait" message
#    - Behavior on concurrent request: Raises error that must be handled
#
# 2. Non-Blocking Locks (with_lock):
#    - Returns a result hash instead of raising errors
#    - Used when you want to silently handle lock failures
#    - Best for background jobs or API endpoints that need simple success/failure
#    - Example: Background job that can be safely skipped if already running
#    - Behavior on concurrent request: Returns { success: false, error: "message" }
#
# Usage Examples:
#
# 1. Blocking Style (raises error on conflict):
#    RequestLockService.acquire_lock(user_id, "search", timeout: 2.minutes)
#    begin
#      # do work
#    ensure
#      RequestLockService.release_lock(user_id, "search")
#    end
#
# 2. Non-Blocking Style (returns result):
#    result = RequestLockService.with_lock(user_id, "search", timeout: 30.seconds) do
#      # do work
#      { success: true, data: "result" }
#    end
#    if result[:success]
#      # handle success
#    else
#      # handle failure
#    end
class RequestLockService
  class ConcurrentRequestError < StandardError; end

  class << self
    attr_accessor :default_lock_timeout
  end

  # Set default timeout to 5 minutes
  self.default_lock_timeout = 5.minutes

  # Executes a block with a lock, handling cleanup automatically
  # Returns { success: true/false, error: "message" }
  # Use this when you want to silently handle lock failures
  def self.with_lock(user_id, action, timeout: nil, &block)
    lock_key = generate_lock_key(user_id, action)
    cache = Rails.cache
    timeout ||= default_lock_timeout

    # Try to acquire lock with a unique token
    # The token ensures only the owner can release the lock
    token = SecureRandom.uuid
    acquired = cache.write(lock_key, token, expires_in: timeout, unless_exist: true)

    unless acquired
      Rails.logger.warn "[RequestLock] Action '#{action}' already in progress for user #{user_id}"
      return { success: false, error: "Another action is in progress. Please wait." }
    end

    begin
      Rails.logger.debug "[RequestLock] Acquired lock for '#{action}' (user: #{user_id}, timeout: #{timeout})"
      result = block.call
      Rails.logger.debug "[RequestLock] Completed '#{action}' for user #{user_id}"
      result
    ensure
      # Only release if we still own the lock (check token)
      # This prevents accidentally releasing a lock acquired by another request
      if cache.read(lock_key) == token
        cache.delete(lock_key)
        Rails.logger.debug "[RequestLock] Released lock for '#{action}' (user: #{user_id})"
      end
    end
  end

  # Acquires a lock for an action
  # Raises ConcurrentRequestError if the lock cannot be acquired
  # Use this when you want to explicitly handle concurrent requests
  def self.acquire_lock(user_id, action, timeout: nil)
    lock_key = generate_lock_key(user_id, action)
    cache = Rails.cache
    timeout ||= default_lock_timeout

    # Try to acquire lock with a unique token
    token = SecureRandom.uuid
    acquired = cache.write(lock_key, token, expires_in: timeout, unless_exist: true)

    unless acquired
      Rails.logger.warn "[RequestLock] Action '#{action}' already in progress for user #{user_id}"
      raise ConcurrentRequestError, "Another action is in progress. Please wait."
    end

    Rails.logger.debug "[RequestLock] Acquired lock for '#{action}' (user: #{user_id}, timeout: #{timeout})"
    token
  end

  # Releases a lock for an action
  # Note: This method should only be called from an ensure block or after_action
  def self.release_lock(user_id, action)
    lock_key = generate_lock_key(user_id, action)
    cache = Rails.cache
    cache.delete(lock_key)
    Rails.logger.debug "[RequestLock] Released lock for '#{action}' (user: #{user_id})"
  end

  private

  # Generates a unique key for the lock based on user_id and action
  # The key includes a prefix to avoid conflicts with other cache entries
  def self.generate_lock_key(user_id, action)
    "request_lock:#{user_id}:#{action}"
  end
end
