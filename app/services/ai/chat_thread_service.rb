module Ai
  class ChatThreadService < BaseService
    include Cacheable

    class << self
      def create_or_load_thread(video_id)
        fetch_cached(thread_key_for(video_id)) do
          {
            success: true,
            messages: [],
            created_at: Time.current
          }
        end
      end

      def save_message(video_id, role, content)
        thread_key = thread_key_for(video_id)
        thread_data = fetch_cached(thread_key) do
          { success: true, messages: [] }
        end

        # Add new message with both raw markdown and rendered HTML
        thread_data[:messages] << {
          role: role,
          content: content,
          content_html: markdown.render(content),
          timestamp: Time.current
        }

        # Cache the updated thread
        cache_service.write(thread_key, thread_data)
        thread_data
      end

      private

      def thread_key_for(video_id)
        "#{Current.user.id}_#{video_id}"
      end

      def markdown
        @markdown ||= Redcarpet::Markdown.new(
          Redcarpet::Render::HTML.new(
            hard_wrap: true,
            link_attributes: { target: "_blank", rel: "noopener" }
          ),
          autolink: true,
          tables: true,
          fenced_code_blocks: true,
          highlight: true,
          space_after_headers: true,
          no_intra_emphasis: true
        )
      end
    end
  end
end
