# frozen_string_literal: true

module Search
  # Provides full-text search functionality across channel metadata.
  # Searches in MongoDB using text indexes and returns matching channel IDs.
  class ChannelSearchService < BaseService
    class << self
      def search_channel_names(query, user_id, type: :channels)
        return [] if query.blank?

        log_info "[Search] Starting channel search for query", context: { query: query, user_id: user_id }

        # Get user's channel IDs for filtering results
        user_channels = UserServices::UserDataService.user_items(user_id, type)
        return [] if user_channels.empty?

        # Search in channel metadata
        log_info "[Search] Searching in channel metadata..."
        matching_channels = search_in_channels(query, user_channels)
        
        # Extract and return matching IDs
        matching_ids = matching_channels.map { |doc| doc["_id"] }
        log_info "[Search] Found #{matching_ids.size} matching channels"
        
        matching_ids
      end

      private

      def search_in_channels(query, user_channels)
        ensure_text_indexes
        collection = mongo_client[:youtube_channel_services_channel_metadata]

        # Build search criteria with text search and user's channels filter
        search_criteria = {
          "$text" => { "$search" => query },
          "_id" => { "$in" => user_channels }
        }

        # Execute search with scoring
        collection.find(
          search_criteria,
          {
            projection: {
              score: { "$meta" => "textScore" },
              "_id" => 1
            }
          }
        ).sort(
          { score: { "$meta" => "textScore" } }
        ).to_a
      end

      def ensure_text_indexes
        collection = mongo_client[:youtube_channel_services_channel_metadata]
        
        # Define text index fields with weights
        text_fields = {
          "data.channel_name" => "text",
          "data.title" => "text",
          "data.description" => "text"
        }

        # Check if index already exists
        return if text_index_exists?(collection, text_fields)

        # Create text index with weights
        log_info "Creating text indexes for channel search"
        create_text_index(collection, text_fields)
      end

      def text_index_exists?(collection, text_fields)
        collection.indexes.each.find do |idx|
          idx["weights"] && text_fields.keys.all? { |field| idx["weights"][field] }
        end
      end

      def create_text_index(collection, text_fields)
        collection.indexes.create_one(
          text_fields,
          {
            name: "channel_search_text_index",
            weights: {
              "data.channel_name" => 10,  # Most important - highest weight
              "data.title" => 8,          # Very important
              "data.description" => 5     # Less important
            }
          }
        )
      rescue Mongo::Error::OperationFailure => e
        log_error "Failed to create text indexes", context: { error: e.message }
        raise
      end

      def mongo_client
        @mongo_client ||= Mongo::Client.new(ENV["MONGODB_URI"])
      end
    end
  end
end 