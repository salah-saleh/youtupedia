class SummaryGeneratorJob < ApplicationJob
  queue_as :default

  def self.schedule(video_id, transcript)
    return if Cache::FileCacheService.new("summaries").exist?(video_id)
    set(wait: 1.second).perform_later(video_id, transcript)
  end

  def perform(video_id, transcript)
    # Use generate_summary which handles caching internally
    result = ChatGptService.generate_summary(video_id, transcript)

    # Only write to cache if we don't have a success result
    unless result[:success]
      Rails.logger.error "Summary generation failed: #{result[:error]}"
    end
  end
end
