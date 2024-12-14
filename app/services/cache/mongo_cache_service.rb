module Cache
  # MongoDB implementation of the cache service with retry mechanism for resilience
  # against temporary connection issues and network hiccups that are common with
  # distributed databases.
  class MongoCacheService < BaseCacheService
    # Include IndexableConcern first
    include IndexableConcern
    # Then include SearchableConcern which depends on it
    include SearchableConcern

    # Maximum number of retry attempts for MongoDB operations
    MAX_RETRIES = 3
    # Delay between retries with exponential backoff (seconds)
    RETRY_DELAY = 0.5

    def write(key, data)
      with_retry do
        log_debug "Writing data for key", key, context: { operation: :write }
        collection.update_one(
          { _id: key },
          { '$set': { data: data } },
          upsert: true
        )
        log_debug "Successfully wrote data for key", key, context: { operation: :write }
        data
      end
    rescue => e
      log_error "Error writing key", key, context: { error: e.message }
      raise
    end

    def read(key)
      log_debug "Reading key", key, context: { operation: :read }
      document = collection.find(_id: key).first
      if document
        log_debug "Found document for key", key, context: { operation: :read, found: true }
        document&.dig("data")
      else
        log_debug "No document found for key", key, context: { operation: :read, found: false }
        nil
      end
    rescue => e
      log_error "Error reading key", key, context: { error: e.message }
      raise
    end

    def exist?(key)
      log_debug "Checking existence of key", key, context: { operation: :exist }
      exists = collection.find(_id: key).count > 0
      log_debug "Key existence result", key, context: { operation: :exist, exists: exists }
      exists
    rescue => e
      log_error "Error checking key existence", key, context: { error: e.message }
      raise
    end

    def delete(key)
      log_debug "Deleting key", key, context: { operation: :delete }
      result = collection.delete_one(_id: key)
      log_debug "Deletion result", key, context: { operation: :delete, deleted_count: result.deleted_count }
    rescue => e
      log_error "Error deleting key", key, context: { error: e.message }
      raise
    end

    def all_keys
      log_debug "Fetching all keys", context: { operation: :all_keys }
      keys = collection.find({}, { projection: { _id: 1 } }).map { |doc| doc[:_id] }
      log_debug "Found keys", context: { operation: :all_keys, count: keys.length }
      keys
    rescue => e
      log_error "Error fetching all keys", context: { error: e.message }
      raise
    end

    private

    def collection
      @collection ||= begin
        log_debug "Initializing collection", context: { namespace: namespace }
        client = Mongoid::Clients.default
        database = client.database
        log_debug "Using database", database.name
        database[namespace]
      end
    end

    def with_retry
      retries = 0
      begin
        yield
      rescue Mongo::Error => e
        retries += 1
        if retries <= MAX_RETRIES
          log_warn "Retry after error", e.message, context: {
            retries: retries,
            max_retries: MAX_RETRIES,
            delay: RETRY_DELAY * retries
          }
          sleep(RETRY_DELAY * retries)
          retry
        else
          raise
        end
      end
    end
  end
end
