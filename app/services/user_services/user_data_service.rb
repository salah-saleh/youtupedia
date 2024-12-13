module UserServices
  class UserDataService
    def self.add_item(user_id, type, item_id)
      log_debug "Adding item", context: { user_id: user_id, type: type, item_id: item_id }
      cache_service = Cache::CacheFactory.build("user_data")
      data = cache_service.fetch("user_#{user_id}") { default_data }

      data[type] ||= []
      data[type].unshift(item_id) unless data[type].include?(item_id)

      cache_service.write("user_#{user_id}", data)
      log_debug "Updated data", data
    end

    def self.remove_item(user_id, type, item_id)
      log_debug "Removing item", context: { user_id: user_id, type: type, item_id: item_id }
      cache_service = Cache::CacheFactory.build("user_data")
      data = cache_service.fetch("user_#{user_id}") { default_data }

      data[type]&.delete(item_id)

      cache_service.write("user_#{user_id}", data)
      log_debug "Updated data", data
    end

    def self.user_items(user_id, type)
      log_debug "Fetching items", context: { user_id: user_id, type: type }
      cache_service = Cache::CacheFactory.build("user_data")
      data = cache_service.fetch("user_#{user_id}") { default_data }
      items = data[type] || []
      log_debug "Found items", items
      items
    end

    def self.has_item?(user_id, type, item_id)
      user_items(user_id, type).include?(item_id)
    end

    private

    def self.default_data
      {
        summaries: [],
        channels: [],
        chat_threads: []
      }
    end
  end
end
