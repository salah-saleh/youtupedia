# RequestLockable is a Rails concern that provides request locking functionality
# to prevent concurrent actions from the same user.
#
# This concern specifically uses BLOCKING locks (RequestLockService.acquire_lock)
# because it's designed for controller actions where you want to show feedback
# to users when concurrent requests occur.
#
# Usage:
#   class MyController < ApplicationController
#     include RequestLockable
#
#     # Basic usage - uses default timeout (1 minute)
#     requires_lock_for :my_action
#
#     # With custom lock name
#     requires_lock_for :my_action, lock_name: :custom_lock
#
#     # With custom timeout
#     requires_lock_for :my_action, timeout: 10.minutes
#
#     # With both custom lock name and timeout
#     requires_lock_for :my_action, lock_name: :custom_lock, timeout: 1.minute
#   end
#
# Configuration:
#   - Default timeout: 1 minute
#   - Default lock name: action name
#
# Behavior:
# 1. When a request comes in, it tries to acquire a lock before executing the action
# 2. If the lock is already held (concurrent request):
#    - For HTML requests: Shows a flash message via Turbo Stream
#    - For JSON requests: Returns a 409 Conflict status
# 3. If the lock is acquired:
#    - Executes the action normally
#    - Releases the lock after completion (even if an error occurs)
# 4. Lock expiration:
#    - Locks automatically expire after the specified timeout
#    - After expiration, new requests can acquire a new lock
#    - This prevents permanent locks if a process crashes
#
# Note: If you need non-blocking behavior, don't use this concern.
# Instead, use RequestLockService.with_lock directly in your controller:
#
#   def my_action
#     result = RequestLockService.with_lock(Current.user.id, :my_action, timeout: 1.minute) do
#       # your action code here
#     end
#     if result[:success]
#       # handle success
#     else
#       # handle failure silently
#     end
#   end
module RequestLockable
  extend ActiveSupport::Concern

  DEFAULT_TIMEOUT = 1.minute

  class_methods do
    def requires_lock_for(action_name, lock_name: nil, timeout: DEFAULT_TIMEOUT)
      before_action only: action_name do
        lock_action = lock_name || action_name
        begin
          RequestLockService.acquire_lock(Current.user.id, lock_action, timeout: timeout)
        rescue RequestLockService::ConcurrentRequestError => e
          # Handle concurrent request error based on the request format
          respond_to do |format|
            # For HTML requests:
            # - Set a flash message
            # - Update the flash message via Turbo Stream
            # - Return early to prevent the action from executing
            format.html {
              flash.now[:alert] = e.message
              render turbo_stream: turbo_stream.update("flash", partial: "shared/flash")
              return
            }
            # For JSON requests:
            # - Return a 409 Conflict status
            # - Include the error message in the response
            # - Return early to prevent the action from executing
            format.json {
              render json: { error: e.message }, status: :conflict
              return
            }
            format.turbo_stream {
              flash.now[:alert] = e.message
              render turbo_stream: turbo_stream.update("flash", partial: "shared/flash")
              return
            }
          end
        end
      end

      # Always release the lock after the action completes
      # This runs even if the action raises an error
      after_action only: action_name do
        lock_action = lock_name || action_name
        RequestLockService.release_lock(Current.user.id, lock_action)
      end
    end
  end
end
