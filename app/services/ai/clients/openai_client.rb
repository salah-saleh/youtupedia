module Ai
  module Clients
    class OpenaiClient < BaseClient
      def initialize
        @client = OpenAI::Client.new(access_token: ENV["OPENAI_API_KEY"])
      end

      def chat(messages)
        params = {
          model: "gpt-4o-mini",
          messages: messages,
          temperature: 0.7
        }
        params[:response_format] = { type: "json_object" }

        response = @client.chat(parameters: params)
        content = response.dig("choices", 0, "message", "content")

        { success: true, content: content }
      rescue => e
        { success: false, error: e.message }
      end
    end
  end
end
