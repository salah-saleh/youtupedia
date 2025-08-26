# Manages user-specific data storage and retrieval using MongoDB caching
# Handles user's video summaries, channel subscriptions, and chat threads
#
# Data Structure:
# {
#   summaries: ["video_id1", "video_id2", ...],     # Recently viewed video summaries
#   channels: ["channel_id1", "channel_id2", ...],  # Subscribed channels
#   chat_threads: ["thread_id1", "thread_id2", ...] # Active chat threads
# }
module UserServices
  class UserDataService < BaseService
    include Persistable
    class << self
      # Adds an item to the specified collection for a user
      # New items are added to the beginning of the list
      #
      # @param user_id [Integer] The user's ID
      # @param type [Symbol] The type of item (:summaries, :channels, :chat_threads)
      # @param item_id [String] The ID of the item to add
      # @return [Hash] The updated user data
      def add_item(user_id, type, item_id)
        log_info "Adding item", context: { user_id: user_id, type: type, item_id: item_id }

        data = fetch_user_data(user_id)
        data[type] ||= []

        if data[type].include?(item_id)
          log_info "Item already exists", context: {
            user_id: user_id,
            type: type,
            item_id: item_id,
            items: data[type]
          }
          return data
        end

        data[type].unshift(item_id)
        write_stored("user_#{user_id}", data)

        log_info "Added new item", context: {
          user_id: user_id,
          type: type,
          item_id: item_id,
          items: data[type]
        }

        data
      end

      def remove_item(user_id, type, item_id)
        log_info "Removing item", context: { user_id: user_id, type: type, item_id: item_id }

        data = fetch_user_data(user_id)
        data[type]&.delete(item_id)

        write_stored("user_#{user_id}", data)
        log_info "Updated data", data
      end

      def user_items(user_id, type)
        log_info "Fetching items", context: { user_id: user_id, type: type }

        data = fetch_user_data(user_id)
        items = data[type] || []

        log_info "Found items", items
        items
      end

      def has_item?(user_id, type, item_id)
        user_items(user_id, type).include?(item_id)
      end

      private

      def fetch_user_data(user_id)
        fetch_stored("user_#{user_id}") do
          default_data
        end
      end

      def default_data
        {
          success: true,
          summaries: [],
          channels: [],
          chat_threads: []
        }
      end
    end
  end
end
