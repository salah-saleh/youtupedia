# frozen_string_literal: true

# SearchableVideos provides full-text search functionality across video summaries and transcripts.
# It combines results from multiple sources (summaries, transcripts) and provides context-aware
# search results with highlighted matches and relevant excerpts.
module SearchableVideos
  extend ActiveSupport::Concern

  # Main search method that finds relevant videos based on a text query.
  # Searches across both summaries and transcripts, combines results,
  # and returns processed results with metadata and context.
  #
  # @param query [String] The search query text
  # @return [Array<Hash>] Array of processed search results with video metadata and context
  def search_videos(query)
    return [] if query.blank?

    log_info "[Search] Starting search for query: #{query}"

    # Get user's video IDs for filtering results
    user_videos = UserServices::UserDataService.user_items(Current.user.id, :summaries)
    return [] if user_videos.empty?

    log_info "[Search] Found #{user_videos.size} videos for user"

    # Search in summaries (GPT-generated content)
    log_info "[Search] Searching in summaries..."
    summary_results = search_in_collection(query, Ai::LlmSummaryService, user_videos)
    log_info "[Search] Found #{summary_results.size} summary results"

    # Process results to add metadata and context
    processed_results = process_search_results(summary_results, query)
    log_info "[Search] Completed search with #{processed_results.size} final results"
    processed_results
  end

  private

  # Performs a search in a specific MongoDB collection using the cache service.
  # Includes a filter for user's videos to optimize the search.
  #
  # @param query [String] The search query
  # @param service_class [Class] The service class to search in
  # @param user_videos [Array<String>] List of video IDs belonging to the user
  # @return [Array<Hash>] Raw search results with keys and scores
  def search_in_collection(query, service_class, user_videos)
    namespace = service_class.name.demodulize.underscore.pluralize
    cache_service = Cache::CacheFactory.build(namespace)
    cache_service.search_text(query, filter: { "_id" => { "$in" => user_videos } })
  end

  # Processes raw search results to add metadata and context.
  # For each result, fetches:
  # - Video metadata (title, channel, etc.)
  # - Summary data (GPT-generated content)
  #
  # @param results [Array<Hash>] Raw search results to process
  # @param query [String] Original search query for context highlighting
  # @return [Array<Hash>] Processed results with full metadata and context
  def process_search_results(results, query)
    metadata_namespace = Youtube::YoutubeVideoMetadataService.name.demodulize.underscore.pluralize
    metadata_cache = Cache::CacheFactory.build(metadata_namespace)

    results.map do |result|
      video_id = result["key"]
      log_info "[Search] Processing result for video: #{video_id}"

      # Step 1: Get video metadata
      metadata = metadata_cache.read(video_id)
      unless metadata&.dig(:success)
        log_info "[Search] No metadata found for video: #{video_id}"
        next
      end

      # Step 2: Build search context with highlighted matches
      context = build_context(query, result["matched_fields"])

      log_info "[Search] Built context for video: #{video_id}"

      # Step 3: Construct final result with all metadata
      {
        video_id: video_id,
        title: metadata.dig(:metadata, :title),
        channel: metadata.dig(:metadata, :channel_title),
        published_at: metadata.dig(:metadata, :published_at),
        thumbnail: metadata.dig(:metadata, :thumbnails, :high),
        score: result["score"] || 0,
        match_context: context
      }
    end.compact
  end

  # Builds a context string showing where the search query matches in the content.
  # Only includes matches from the summary text.
  #
  # @param query [String] The search query to highlight
  # @param matched_fields [String] The matched fields from the search
  # @return [String] Context with summary matches
  def build_context(query, matched_fields)
    return "" unless matched_fields

    # Look for matches in summary
    if summary_context = extract_context(matched_fields, query)
      "#{summary_context}"
    else
      ""
    end
  end

  # Extracts context around search query matches in text.
  # Shows ~100 characters before and after each match.
  # Handles multi-word queries by finding matches for each word.
  #
  # @param text [String] The text to search in
  # @param query [String] The search query to find
  # @return [String] Combined context snippets with ellipsis
  def extract_context(text, query)
    return "" unless text.present? && text.is_a?(String)

    # Split query into words and remove empty strings
    query_words = query.downcase.split(/\s+/).reject(&:empty?)
    return "" if query_words.empty?

    # Find positions for all query words
    positions = []
    query_words.each do |word|
      current_pos = 0
      while (pos = text.downcase.index(word, current_pos))
        positions << {
          start: pos,
          length: word.length,
          word: word
        }
        current_pos = pos + 1
      end
    end

    return "" if positions.empty?

    # Sort positions by their location in text
    positions.sort_by! { |pos| pos[:start] }

    # Merge overlapping or close contexts
    contexts = []
    current_context = nil

    positions.each do |position|
      if current_context.nil? ||
         position[:start] > current_context[:end_pos] + 100 # Start new context if too far from previous

        # Add previous context if it exists
        if current_context
          contexts << extract_snippet(text, current_context[:start_pos], current_context[:end_pos])
        end

        # Start new context
        current_context = {
          start_pos: [ position[:start] - 100, 0 ].max,
          end_pos: [ position[:start] + position[:length] + 100, text.length ].min
        }
      else
        # Extend current context
        current_context[:end_pos] = [ position[:start] + position[:length] + 100, text.length ].min
      end
    end

    # Add final context
    contexts << extract_snippet(text, current_context[:start_pos], current_context[:end_pos]) if current_context

    # Join all contexts with newlines
    contexts.join("\n...\n")
  end

  private

  def extract_snippet(text, start_pos, end_pos)
    context = text[start_pos...end_pos]
    context = "..." + context if start_pos > 0
    context = context + "..." if end_pos < text.length
    context
  end
end
