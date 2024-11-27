class HomeController < ApplicationController
  layout "dashboard"

  def index
    if user_signed_in?
      @recent_summaries = load_recent_summaries
      render layout: "dashboard"
    else
      render layout: "application"
    end
  end

  private

  def load_recent_summaries
    metadata_dir = Rails.root.join("tmp/metadata")
    return [] unless Dir.exist?(metadata_dir)

    Dir.glob(metadata_dir.join("*.json"))
      .sort_by { |f| File.mtime(f) }
      .reverse
      .first(9)
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
    Rails.logger.error "Error loading recent summaries: #{e.message}"
    []
  end
end
