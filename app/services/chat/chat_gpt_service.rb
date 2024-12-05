module Chat
  class ChatGptService < BaseAsyncService
    def perform(transcript, metadata)
      return { success: false, error: "Transcript is too short" } if transcript.length < 500

      client = OpenAI::Client.new(access_token: ENV["OPENAI_API_KEY"])
      response = client.chat(
        parameters: {
          model: "gpt-4o-mini",
          messages: [
            {
              role: "system",
              content: system_prompt
            },
            {
              role: "user",
              content: "Please summarize this video transcript: #{transcript} with the following metadata: #{metadata}"
            }
          ],
          temperature: 0.7,
          response_format: { type: "json_object" }
        }
      )

      content = response.dig("choices", 0, "message", "content")
      return { success: false, error: "No content received" } unless content

      begin
        result = JSON.parse(content)

        unless result["tldr"] && result["takeaways"] && result["tags"] && result["summary"]
          return { success: false, error: "Missing required fields in response" }
        end

        {
          success: true,
          tldr: result["tldr"],
          takeaways: result["takeaways"],
          tags: result["tags"],
          summary: result["summary"]
        }
      rescue JSON::ParserError => e
        Rails.logger.error "JSON parsing error: #{e.message}"
        Rails.logger.error "Full error details: #{e.full_message}"
        Rails.logger.error "Raw content causing error: #{content}"
        { success: false, error: "Failed to parse summary: #{e.message}" }
      rescue => e
        Rails.logger.error "Summary Error: #{e.message}"
        Rails.logger.error "Full error details: #{e.full_message}"
        Rails.logger.error "Raw content causing error: #{content}"
        { success: false, error: "Failed to generate summary: #{e.message}" }
      end
    end

    def self.answer_question(video_id, question, transcript, metadata)
      client = OpenAI::Client.new(access_token: ENV["OPENAI_API_KEY"])
      thread_data = Chat::ChatThreadService.create_or_load_thread(video_id)

      # Build conversation history
      messages = [
        {
          role: "system",
          content: <<~PROMPT
            You are a helpful assistant answering questions about a video transcript.
            Provide clear and concise answers based on the transcript content.
            Please answer strictly about the transcript content.
            If asked about any other topic, please say you can only answer about the transcript content.
            Your response must be in markdown format.
          PROMPT
        },
        {
          role: "user",
          content: "Here is the transcript to analyze: #{transcript} with the following metadata: #{metadata}"
        }
      ]

      # Add conversation history
      thread_data[:messages].each do |msg|
        messages << {
          role: msg[:role],
          content: msg[:content]
        }
      end

      # Add the new question
      messages << {
        role: "user",
        content: question
      }

      response = client.chat(
        parameters: {
          model: "gpt-4o-mini",
          messages: messages,
          temperature: 0.7
        }
      )

      content = response.dig("choices", 0, "message", "content")
      return { success: false, error: "No content received" } unless content

      Chat::ChatThreadService.save_message(video_id, "user", question)
      Chat::ChatThreadService.save_message(video_id, "assistant", content)

      { success: true, answer: content }
    rescue => e
      Rails.logger.error "Chat GPT Error: #{e.message}"
      Rails.logger.error "Full error details: #{e.full_message}"
      { success: false, error: "Failed to process question: #{e.message}" }
    end

    private

    def system_prompt
      <<~PROMPT
        You are an AI assistant that helps summarize video transcripts.
        Try to comprehend and infer meaning of the messages in the transcript.
        Please analyze the transcript and provide:
        1. A brief TLDR
        2. Ten key conculusions or takeaways with timestamps. PLease be informative and not just a list of topics.
        3. Important tags/topics with timestamps
        4. A detailed summary of 500 to 700 words that references timestamps

        Make sure your response is a valid JSON object with no trailing commas.
        Do not include any explanatory text outside the JSON structure.
        The response must contain exactly these fields:
        {
          "tldr": "A brief summary here, mentioning speakers if possible",
          "takeaways": [
            {"timestamp": 123, "content": "Key point 1"},
            {"timestamp": 456, "content": "Key point 2"}
          ],
          "tags": [
            {"timestamp": 123, "tag": "Topic 1"},
            {"timestamp": 456, "tag": "Topic 2"}
          ],
          "summary": "Detailed summary with (123) timestamp references"
        }
      PROMPT
    end
  end
end
