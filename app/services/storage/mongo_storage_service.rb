module Storage
  # MongoDB-based storage implementation with retry mechanism
  # Handles BSON document conversion and provides resilient storage operations
  class MongoStorageService < BaseStorageService
    # Maximum retry attempts for MongoDB operations
    MAX_RETRIES = 3
    # Delay between retries (seconds)
    RETRY_DELAY = 0.5

    # Writes data to MongoDB storage
    # @param key [String] Storage key
    # @param data [Hash] Data to store
    # @return [Hash] Stored data
    def write(key, data)
      with_retry do
        log_info "Writing data to storage", key, context: { operation: :write }
        collection.update_one(
          { _id: key },
          { '$set': { data: data } },
          upsert: true
        )
        log_info "Successfully wrote data to storage", key, context: { operation: :write }
        data
      end
    rescue => e
      log_error "Error writing to storage", key, context: { error: e.message }
      raise
    end

    # Reads data from MongoDB storage
    # @param key [String] Storage key
    # @return [Hash, nil] Stored data or nil if not found
    def read(key)
      log_info "Reading from storage", key, context: { operation: :read }
      document = collection.find(_id: key).first
      if document
        log_info "Found document in storage", key, context: { operation: :read, found: true }
        data = document&.dig("data")
        return nil unless data

        begin
          case data
          when BSON::Document
            data.to_h.deep_symbolize_keys
          when Hash
            data.symbolize_keys
          else
            log_warn "Unexpected data type in storage", context: { type: data.class.name }
            data
          end
        rescue => e
          log_error "Data conversion error from storage", context: { error: e.message }
          nil
        end
      else
        log_info "No document found in storage", key, context: { operation: :read, found: false }
        nil
      end
    rescue => e
      log_error "Error reading from storage", key, context: { error: e.message }
      raise
    end

    # Checks if key exists in storage
    # @param key [String] Storage key
    # @return [Boolean] True if key exists
    def exist?(key)
      log_info "Checking existence in storage", key, context: { operation: :exist }
      exists = collection.find(_id: key).count > 0
      log_info "Storage existence result", key, context: { operation: :exist, exists: exists }
      exists
    rescue => e
      log_error "Error checking storage existence", key, context: { error: e.message }
      raise
    end

    def delete(key)
      log_info "Deleting from storage", key, context: { operation: :delete }
      result = collection.delete_one(_id: key)
      log_info "Storage deletion result", key, context: { operation: :delete, deleted_count: result.deleted_count }
    rescue => e
      log_error "Error deleting from storage", key, context: { error: e.message }
      raise
    end

    def all_keys
      log_info "Fetching all keys from storage", context: { operation: :all_keys }
      keys = collection.find({}, { projection: { _id: 1 } }).map { |doc| doc[:_id] }
      log_info "Found keys in storage", context: { operation: :all_keys, count: keys.length }
      keys
    rescue => e
      log_error "Error fetching all keys from storage", context: { error: e.message }
      raise
    end

    private

    # Gets or initializes MongoDB collection for storage
    # Ensures collection exists and is properly configured
    # @return [Mongo::Collection] MongoDB collection for storage
    def collection
      @collection ||= begin
        client = Mongoid::Clients.default
        database = client.database
        log_info "Using database for storage", database.name
        database[namespace]
      end
    end

    # Executes block with retry mechanism for MongoDB operations
    # Implements exponential backoff for retries
    # @yield Block to execute with retry
    # @raise [Mongo::Error] If max retries exceeded
    # @return [Object] Result of the block
    def with_retry
      retries = 0
      begin
        yield
      rescue Mongo::Error => e
        retries += 1
        if retries <= MAX_RETRIES
          log_warn "Retrying storage operation after error", e.message, context: {
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
