module Ai
  module Clients
    class BaseClient
      def chat(messages)
        raise NotImplementedError, "#{self.class} must implement #chat"
      end
    end
  end
end
