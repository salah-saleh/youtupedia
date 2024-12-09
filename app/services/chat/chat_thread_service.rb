module Chat
  class ChatThreadService
    def self.create_or_load_thread(video_id)
      cache_service = Cache::CacheFactory.build("chat_threads")
      thread_key = thread_key_for(video_id)

      thread_data = cache_service.fetch(thread_key) do
        {
          messages: [],
          created_at: Time.current
        }
      end

      # Convert markdown to HTML for each message when loading
      thread_data[:messages].each do |message|
        message[:content_html] = markdown.render(message[:content])
      end

      thread_data
    end

    def self.save_message(video_id, role, content)
      cache_service = Cache::CacheFactory.build("chat_threads")
      thread_key = thread_key_for(video_id)
      thread_data = cache_service.fetch(thread_key) || { messages: [] }

      # Add new message with both raw markdown and rendered HTML
      thread_data[:messages] << {
        role: role,
        content: content,
        content_html: markdown.render(content),
        timestamp: Time.current
      }

      cache_service.write(thread_key, thread_data)
      thread_data
    end

    private

    def self.thread_key_for(video_id)
      "#{Current.user.id}_#{video_id}"
    end

    def self.markdown
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
