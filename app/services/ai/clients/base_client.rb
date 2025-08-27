module Ai
  module Clients
    class BaseClient
      def chat(messages, video_id: nil, operation_type: nil)
        raise NotImplementedError, "#{self.class} must implement #chat"
      end
    end
  end
end
