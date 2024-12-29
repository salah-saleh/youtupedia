# Handles fetching transcript and generating summary for a video
class SummaryJob < ApplicationJob
  queue_as :default

  def perform(video_id)
    # First get metadata
    metadata = Youtube::YoutubeVideoMetadataService.fetch_metadata(video_id)
    return unless metadata[:success]

    # Then get transcript
    transcript = Youtube::YoutubeVideoTranscriptService.new.process_task(video_id)

    # Cache the transcript result
    cache_service = Cache::CacheFactory.build(Youtube::YoutubeVideoTranscriptService.name.demodulize.underscore.pluralize)
    cache_service.write(video_id, transcript)
    return transcript unless transcript[:success]

    # Finally generate summary
    result = Chat::ChatGptService.new.process_task(video_id, transcript[:transcript_full], metadata)
    # Cache the summary result
    cache_service = Cache::CacheFactory.build(Chat::ChatGptService.name.demodulize.underscore.pluralize)
    cache_service.write(video_id, result)
  end
end
