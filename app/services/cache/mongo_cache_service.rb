module Cache
  # MongoDB implementation of the cache service with retry mechanism for resilience
  # against temporary connection issues and network hiccups that are common with
  # distributed databases.
  class MongoCacheService < BaseCacheService
    # Maximum number of retry attempts for MongoDB operations
    MAX_RETRIES = 3
    # Delay between retries with exponential backoff (seconds)
    RETRY_DELAY = 0.5

    def write(key, data)
      with_retry do
        Rails.logger.debug "CACHE [MongoDB] Writing data for '#{key}'"
        collection.update_one(
          { _id: key },
          { '$set': { data: data } },
          upsert: true
        )
        Rails.logger.debug "CACHE [MongoDB] Successfully wrote data for '#{key}'"
        data
      end
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

    def with_retry
      retries = 0
      begin
        yield
      rescue Mongo::Error => e
        retries += 1
        if retries <= MAX_RETRIES
          Rails.logger.warn "CACHE [MongoDB] Retry #{retries}/#{MAX_RETRIES} after error: #{e.message}"
          sleep(RETRY_DELAY * retries)
          retry
        else
          raise
        end
      end
    end
  end
end
