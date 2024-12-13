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

    def all_keys
      Rails.logger.debug "CACHE [MongoDB] Fetching all keys from '#{namespace}'"
      keys = collection.find({}, { projection: { _id: 1 } }).map { |doc| doc[:_id] }
      Rails.logger.debug "CACHE [MongoDB] Found #{keys.length} keys"
      keys
    end

    def search_text(query, options = {})
      Rails.logger.debug "CACHE [MongoDB] Performing text search for '#{query}' in namespace '#{namespace}'"

      # Log a sample document to understand the structure
      sample_doc = collection.find.first
      Rails.logger.debug "CACHE [MongoDB] Sample document structure: #{sample_doc.inspect}"

      # Construct a regex search pattern for more flexible matching
      regex_pattern = Regexp.new(Regexp.escape(query), Regexp::IGNORECASE)

      # Build the search conditions based on the collection
      search_conditions = case namespace
      when "transcripts/full"
        { "data.transcript" => regex_pattern }
      when Chat::ChatGptService.cache_namespace
        {
          "data.success" => true,
          "$or" => [
            { "data.summary" => regex_pattern },
            { "data.tldr" => regex_pattern },
            { "data.takeaways.content" => regex_pattern },
            { "data.tags.tag" => regex_pattern }
          ]
        }
      else
        { "data" => regex_pattern }
      end

      Rails.logger.debug "CACHE [MongoDB] Search conditions: #{search_conditions.inspect}"

      pipeline = [
        { "$match" => search_conditions },
        { "$addFields" => {
          "key" => "$_id",
          "score" => { "$add" => [
            { "$cond" => [
              { "$regexMatch" => {
                "input" => { "$ifNull" => [ "$data.tldr", "" ] },
                "regex" => regex_pattern
              } },
              3,  # score for TLDR matches
              0
            ] },
            { "$cond" => [
              { "$regexMatch" => {
                "input" => { "$ifNull" => [ "$data.summary", "" ] },
                "regex" => regex_pattern
              } },
              3,  # score for summary matches
              0
            ] },
            { "$cond" => [
              { "$gt" => [
                { "$size" => {
                  "$filter" => {
                    "input" => { "$ifNull" => [ "$data.takeaways", [] ] },
                    "as" => "takeaway",
                    "cond" => {
                      "$regexMatch" => {
                        "input" => "$$takeaway.content",
                        "regex" => regex_pattern
                      }
                    }
                  }
                } },
                0
              ] },
              3,  # Score for takeaway matches
              0
            ] },
            { "$cond" => [
              { "$gt" => [
                { "$size" => {
                  "$filter" => {
                    "input" => { "$ifNull" => [ "$data.tags", [] ] },
                    "as" => "tag",
                    "cond" => {
                      "$regexMatch" => {
                        "input" => "$$tag.tag",
                        "regex" => regex_pattern
                      }
                    }
                  }
                } },
                0
              ] },
              3,  # Score for tag matches
              0
            ] }
          ] }
        } },
        { "$sort" => { "score" => -1 } },
        { "$limit" => options[:limit] || 10 }
      ]

      Rails.logger.debug "CACHE [MongoDB] Executing pipeline: #{pipeline.inspect}"

      results = collection.aggregate(pipeline).to_a
      Rails.logger.debug "CACHE [MongoDB] Found #{results.length} matches"
      Rails.logger.debug "CACHE [MongoDB] First result (if any): #{results.first.inspect}"

      results
    end

    private

    def collection
      @collection ||= begin
        Rails.logger.debug "CACHE [MongoDB] Initializing collection for namespace '#{namespace}'"
        client = Mongoid::Clients.default
        database = client.database
        Rails.logger.debug "CACHE [MongoDB] Using database: #{database.name}"
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
