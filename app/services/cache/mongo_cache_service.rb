module Cache
  class MongoCacheService < BaseCacheService
    def write(key, data)
      Rails.logger.debug "CACHE [MongoDB] Writing data for '#{key}'"
      collection.update_one(
        { _id: key },
        { '$set': { data: data } },
        upsert: true
      )
      Rails.logger.debug "CACHE [MongoDB] Successfully wrote data for '#{key}'"
      data
    rescue => e
      Rails.logger.error "CACHE [MongoDB] Error writing '#{key}': #{e.message}"
      raise
    end

    def read(key)
      Rails.logger.debug "CACHE [MongoDB] Reading '#{key}'"
      document = collection.find(_id: key).first
      if document
        Rails.logger.debug "CACHE [MongoDB] Found document for '#{key}'"
        document&.dig("data")
      else
        Rails.logger.debug "CACHE [MongoDB] No document found for '#{key}'"
        nil
      end
    end

    def exist?(key)
      Rails.logger.debug "CACHE [MongoDB] Checking existence of '#{key}'"
      exists = collection.find(_id: key).count > 0
      Rails.logger.debug "CACHE [MongoDB] Document '#{key}' exists: #{exists}"
      exists
    end

    def delete(key)
      Rails.logger.debug "CACHE [MongoDB] Deleting '#{key}'"
      result = collection.delete_one(_id: key)
      Rails.logger.debug "CACHE [MongoDB] Deleted #{result.deleted_count} document(s) for '#{key}'"
    end

    private

    def collection
      @collection ||= begin
        Rails.logger.debug "CACHE [MongoDB] Initializing collection for namespace '#{namespace}'"
        client = Mongoid::Clients.default
        client[namespace]
      end
    end
  end
end
