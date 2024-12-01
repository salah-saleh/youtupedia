module SummaryLoader
  extend ActiveSupport::Concern

  def load_recent_summaries
    metadata_dir = Rails.root.join("tmp/cache/metadata")
    return [] unless Dir.exist?(metadata_dir)

    Dir.glob(metadata_dir.join("*.json"))
      .sort_by { |f| File.mtime(f) }
      .reverse
      .first(20)
      .map do |file|
        video_id = File.basename(file, ".json")
        metadata = JSON.parse(File.read(file), symbolize_names: true)
        {
          video_id: video_id,
          title: metadata.dig(:metadata, :title),
          channel: metadata.dig(:metadata, :channel_title),
          published_at: metadata.dig(:metadata, :published_at),
          thumbnail: metadata.dig(:metadata, :thumbnails, :medium)
        }
    end
  rescue => e
    Rails.logger.error "Error loading summaries: #{e.message}"
    []
  end
end
