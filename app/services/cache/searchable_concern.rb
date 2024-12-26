module Cache
  module SearchableConcern
    extend ActiveSupport::Concern

    # Performs a text search across MongoDB documents using text indexes.
    # This method first ensures text indexes exist, then executes the search
    # using MongoDB's $text operator.
    #
    # @param query [String] The search text to find in documents
    # @param options [Hash] Additional search options
    # @option options [Hash] :filter Additional MongoDB filter conditions
    # @return [Array<Hash>] Array of search results with scores and matched content
    def search_text(query, options = {})
      # Requires IndexableConcern to be included in the same class
      # for ensure_text_indexes method.
      unless respond_to?(:ensure_text_indexes)
        raise "#{self.class.name} must include IndexableConcern for search functionality"
      end

      log_info "Performing text search", query, context: {
        operation: :search,
        namespace: namespace,
        options: options
      }

      # Create text index if it doesn't exist
      ensure_text_indexes

      begin
        perform_text_search(query, options)
      rescue Mongo::Error::OperationFailure => e
        log_error "Search failed", context: {
          error: e.message,
          namespace: namespace,
          query: query
        }
        raise
      end
    end

    private

    # Executes the MongoDB text search query and formats the results.
    # Uses MongoDB's $text operator with metadata scoring for relevance ranking.
    #
    # @param query [String] The search text
    # @param options [Hash] Additional search options
    # @return [Array<Hash>] Formatted search results
    def perform_text_search(query, options)
      projection = build_projection
      # Combine text search with any additional filters
      search_criteria = {
        "$text" => { "$search" => query }
      }
      search_criteria.merge!(options[:filter]) if options[:filter]

      results = collection.find(
        search_criteria,
        {
          projection: projection
        }
      ).sort(
        { score: { "$meta" => "textScore" } }
      ).limit(10).to_a

      log_info "Text search results", context: {
        count: results.length,
        scores: results.map { |r| r["score"] },
        criteria: search_criteria  # Log the full search criteria
      }

      format_search_results(results)
    end

    # Builds the MongoDB projection document for search queries.
    # Includes score metadata and relevant fields from the documents.
    #
    # @return [Hash] MongoDB projection specification
    def build_projection
      {
        score: { "$meta" => "textScore" },
        "_id" => 1,
        "data.summary" => 1 # only include summary for now
        # "data.tldr" => 1,
        # "data.takeaways" => 1
      }
    end

    # Formats raw MongoDB search results into a consistent structure.
    # Extracts relevant fields and includes search score metadata.
    #
    # @param results [Array<Hash>] Raw MongoDB search results
    # @return [Array<Hash>] Formatted results with key, score, and matched content
    def format_search_results(results)
      return [] unless results.any?

      results.map do |doc|
        {
          "key" => doc["_id"],
          "score" => doc["score"],
          "matched_fields" => extract_matched_fields(doc)
        }
      end
    end

    # Extracts and combines searchable content from document fields.
    # Concatenates summary, TLDR, and takeaways content for matching.
    #
    # @param doc [Hash] MongoDB document with search results
    # @return [String] Combined text from all matched fields
    def extract_matched_fields(doc)
      [
        doc.dig("data", "summary")
        # doc.dig("data", "tldr"),
        # doc.dig("data", "takeaways")&.map { |t| t["content"] }
      ].flatten.compact.join(" ")
    end
  end
end
