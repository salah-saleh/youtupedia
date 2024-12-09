module UserServices
  class UserDataService
    def self.add_item(user_id, type, item_id)
      Rails.logger.debug "UserDataService: Adding #{item_id} to #{type} for user #{user_id}"
      cache_service = Cache::CacheFactory.build("user_data")
      data = cache_service.fetch("user_#{user_id}") { default_data }

      data[type] ||= []
      data[type].unshift(item_id) unless data[type].include?(item_id)

      cache_service.write("user_#{user_id}", data)
      Rails.logger.debug "UserDataService: Updated data: #{data.inspect}"
    end

    def self.remove_item(user_id, type, item_id)
      Rails.logger.debug "UserDataService: Removing #{item_id} from #{type} for user #{user_id}"
      cache_service = Cache::CacheFactory.build("user_data")
      data = cache_service.fetch("user_#{user_id}") { default_data }

      data[type]&.delete(item_id)

      cache_service.write("user_#{user_id}", data)
      Rails.logger.debug "UserDataService: Updated data: #{data.inspect}"
    end

    def self.user_items(user_id, type)
      Rails.logger.debug "UserDataService: Fetching #{type} for user #{user_id}"
      cache_service = Cache::CacheFactory.build("user_data")
      data = cache_service.fetch("user_#{user_id}") { default_data }
      items = data[type] || []
      Rails.logger.debug "UserDataService: Found items: #{items.inspect}"
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
