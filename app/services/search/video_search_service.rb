# frozen_string_literal: true

module Search
  # Provides full-text search functionality across video summaries.
  # Searches in MongoDB using text indexes and returns matching video IDs.
  class VideoSearchService < BaseService
    class << self
      def search_video_ids(query, user_id)
        return [] if query.blank?

        log_info "[Search] Starting search for query", context: { query: query, user_id: user_id }

        # Get user's video IDs for filtering results
        user_videos = UserServices::UserDataService.user_items(user_id, :summaries)
        return [] if user_videos.empty?

        # Search in summaries (GPT-generated content)
        log_info "[Search] Searching in summaries..."
        matching_videos = search_in_summaries(query, user_videos)
        
        # Extract and return matching IDs
        matching_ids = matching_videos.map { |doc| doc["_id"] }
        log_info "[Search] Found #{matching_ids.size} matching videos"
        
        matching_ids
      end

      private

      def search_in_summaries(query, user_videos)
        ensure_text_indexes
        collection = mongo_client[:llm_summary_services]

        # Build search criteria with text search and user's videos filter
        search_criteria = {
          "$text" => { "$search" => query },
          "_id" => { "$in" => user_videos }
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
        collection = mongo_client[:llm_summary_services]
        
        # Define text index fields with weights
        text_fields = {
          "data.summary" => "text",
          "data.tldr" => "text",
          "data.takeaways.content" => "text"
        }

        # Check if index already exists
        return if text_index_exists?(collection, text_fields)

        # Create text index with weights
        log_info "Creating text indexes for video search"
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
            name: "video_search_text_index",
            weights: {
              "data.tldr" => 10,      # Most important - highest weight
              "data.summary" => 8,     # Very important
              "data.takeaways.content" => 8  # Very important
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