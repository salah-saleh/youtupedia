module Cache
  module IndexableConcern
    extend ActiveSupport::Concern


    # Ensures that text search indexes exist for the MongoDB collection.
    # Creates indexes if they don't exist, with appropriate weights for different fields.
    # Text indexes enable full-text search capabilities across specified fields.
    #
    # The following fields are indexed with their respective weights:
    # - data.tldr (weight: 10) - Highest priority for search matches
    # - data.summary (weight: 8) - High priority for search matches
    # - data.takeaways.content (weight: 8) - Medium priority for search matches
    #
    # @raise [Mongo::Error::OperationFailure] if index creation fails
    def ensure_text_indexes
      text_fields = {
        "data.summary" => "text",
        "data.tldr" => "text",
        "data.takeaways.content" => "text"
      }

      begin
        return if text_index_exists?(text_fields)

        log_debug "Creating text indexes", context: {
          namespace: namespace,
          fields: text_fields
        }

        create_text_index(text_fields)
        log_debug "Successfully created text indexes"
      rescue Mongo::Error::OperationFailure => e
        log_error "Failed to create text indexes", context: { error: e.message }
        raise
      end
    end

    private

    # Checks if the required text indexes already exist in the collection.
    # Verifies that all specified fields are properly indexed with weights.
    #
    # @param text_fields [Hash] The fields that should be text indexed
    # @return [Boolean] true if required indexes exist, false otherwise
    def text_index_exists?(text_fields)
      collection.indexes.each.find do |idx|
        idx["weights"] && text_fields.keys.all? { |field| idx["weights"][field] }
      end
    end

    # Creates a new text index in the MongoDB collection.
    # Configures field weights to prioritize certain fields in search results.
    # Document B:
    # - Summary contains "Rails" twice (score: 2.0 × 8 = 16)
    # Total score: 16
    # Document C:
    # - Takeaways contains "Rails" once (score: 1.0 × 8 = 8)
    # - TLDR contains "Rails" once (score: 1.0 × 10 = 10)
    # Total score: 18
    #
    # @param text_fields [Hash] The fields to create text indexes for
    # @return [String] The name of the created index
    # @raise [Mongo::Error::OperationFailure] if index creation fails
    def create_text_index(text_fields)
      collection.indexes.create_one(
        text_fields,
        {
          name: "#{namespace}_text_search",
          weights: {
            "data.tldr" => 10,      # Most important - highest weight
            "data.summary" => 8,     # Very important
            "data.takeaways.content" => 8  # Very important
          }
        }
      )
    end
  end
end
