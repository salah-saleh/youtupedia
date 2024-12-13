# frozen_string_literal: true

module SearchableVideos
  extend ActiveSupport::Concern

  private

  def search_videos(query, user_id)
    Rails.logger.debug "[Search] Starting search for query: #{query}"

    # Get user's video IDs
    user_video_ids = UserServices::UserDataService.user_items(user_id, :summaries)
    return [] if user_video_ids.empty?

    Rails.logger.debug "[Search] Found #{user_video_ids.length} videos for user"

    # Initialize cache services
    summaries_cache = Cache::CacheFactory.build(Chat::ChatGptService.cache_namespace)
    transcript_cache = Cache::CacheFactory.build("transcripts/full")
    metadata_cache = Cache::CacheFactory.build("metadata")

    # Search in summaries and transcripts
    Rails.logger.debug "[Search] Searching in summaries..."
    summary_results = summaries_cache.search_text(query, limit: 20)
    Rails.logger.debug "[Search] Found #{summary_results.length} summary results"

    Rails.logger.debug "[Search] Searching in transcripts..."
    transcript_results = transcript_cache.search_text(query, limit: 20)
    Rails.logger.debug "[Search] Found #{transcript_results.length} transcript results"

    # Combine and deduplicate results, filtering for user's videos
    all_results = (summary_results + transcript_results)
      .select { |r| user_video_ids.include?(r[:_id]) }
      .uniq { |r| r[:_id] }

    Rails.logger.debug "[Search] Combined unique results for user: #{all_results.length}"

    # Sort by score and limit to top 20
    all_results = all_results.sort_by { |r| -r[:score] }.first(20)

    # Build full result data
    results = all_results.map do |result|
      video_id = result[:_id]
      Rails.logger.debug "[Search] Processing result for video: #{video_id}"

      metadata = metadata_cache.read(video_id)
      unless metadata&.dig(:success)
        Rails.logger.debug "[Search] No metadata found for video: #{video_id}"
        next
      end

      summary_data = summaries_cache.read(video_id)
      transcript_data = transcript_cache.read(video_id)

      unless summary_data&.dig(:success) && transcript_data
        Rails.logger.debug "[Search] Missing summary or transcript for video: #{video_id}"
        next
      end

      # Build context from all sources
      context = build_context(query, transcript_data, summary_data)

      Rails.logger.debug "[Search] Built context for video: #{video_id}"

      {
        video_id: video_id,
        title: metadata.dig(:metadata, :title),
        channel: metadata.dig(:metadata, :channel_title),
        published_at: metadata.dig(:metadata, :published_at),
        thumbnail: metadata.dig(:metadata, :thumbnails, :high),
        score: result[:score],
        match_context: context
      }
    end.compact

    Rails.logger.info "[Search] Completed search with #{results.length} final results"
    results
  end

  def build_context(query, transcript_data, summary_data)
    contexts = []

    # Add transcript context if found
    if transcript_context = extract_context(transcript_data[:transcript], query)
      contexts << transcript_context
    end

    # Add summary context if found
    if summary_context = extract_context(summary_data[:summary], query)
      contexts << "Summary: #{summary_context}"
    end

    # Add matching takeaways
    if summary_data[:takeaways].is_a?(Array)
      matching_takeaways = summary_data[:takeaways].select do |takeaway|
        takeaway[:content].to_s.downcase.include?(query.downcase)
      end

      if matching_takeaways.any?
        takeaway_texts = matching_takeaways.map do |takeaway|
          "#{takeaway[:content]} (#{takeaway[:timestamp]})"
        end
        contexts << "Takeaways:\n#{takeaway_texts.join("\n")}"
      end
    end

    # Add matching TLDR if found
    if summary_data[:tldr].to_s.downcase.include?(query.downcase)
      contexts << "TLDR: #{summary_data[:tldr]}"
    end

    # Join all contexts with separators
    contexts.join("\n\n")
  end

  def extract_context(text, query)
    return "" unless text.present? && text.is_a?(String)

    # Find all occurrences of the query
    positions = []
    current_pos = 0
    while (pos = text.downcase.index(query.downcase, current_pos))
      positions << pos
      current_pos = pos + 1
    end

    return "" if positions.empty?

    # Extract context around each occurrence
    contexts = positions.map do |position|
      start_pos = [ position - 100, 0 ].max
      end_pos = [ position + query.length + 100, text.length ].min

      # Extract the context and add ellipsis if needed
      context = text[start_pos...end_pos]
      context = "..." + context if start_pos > 0
      context = context + "..." if end_pos < text.length

      context
    end

    # Join all contexts
    contexts.join("\n")
  end
end
