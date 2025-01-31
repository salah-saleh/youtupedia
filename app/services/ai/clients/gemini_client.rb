module Ai
  module Clients
    class GeminiClient < BaseClient
      include PythonScriptable

      def chat(messages)
        # Get the system prompt content
        system_prompt = messages.find { |m| m[:role] == "system" }&.fetch(:content, "")

        # Determine which script to use based on the system prompt content
        script_name = if system_prompt.include?("expanding and providing detailed explanations")
          "gemini_expanded_takeaway_client.py"
        else
          "gemini_summary_client.py"
        end

        # Convert Ruby symbols to strings for JSON serialization
        formatted_messages = messages.map do |msg|
          {
            "role" => msg[:role],
            "content" => msg[:content]
          }
        end

        result = run_python_script(script_name, { "messages" => formatted_messages })

        if result[:success]
          { success: true, content: result[:content] }
        else
          { success: false, error: result[:error] }
        end
      end
    end
  end
end
