module Ai
  module Clients
    class GeminiClient < BaseClient
      include PythonScriptable

      def chat(messages)
        script_name = "gemini_summary_client.py"
        result = run_python_script(script_name, messages)

        if result[:success]
          { success: true, content: result[:content] }
        else
          { success: false, error: result[:error] }
        end
      end
    end
  end
end
