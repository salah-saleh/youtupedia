module Ai
  class ChatGptService < BaseService
    include AsyncProcessable
    include Cacheable

    class << self
      # Fetches summary from cache
      # @param video_id [String] The YouTube video ID
      # @return [Hash, nil] Summary data if cached, nil if processing started
      def fetch_summary(video_id)
        fetch_cached(video_id, expires_in: nil)
      end

      def answer_question(video_id, question, transcript, metadata)
        client = OpenAI::Client.new(access_token: ENV["OPENAI_API_KEY"])
        thread_data = Ai::ChatThreadService.create_or_load_thread(video_id)

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

        Ai::ChatThreadService.save_message(video_id, "user", question)
        Ai::ChatThreadService.save_message(video_id, "assistant", content)

        { success: true, answer: content }
      rescue => e
        log_error "Chat GPT error", context: {
          error: e.message,
          backtrace: e.full_message,
          video_id: video_id,
          question: question
        }
        { success: false, error: "Failed to process question: #{e.message}" }
      end
    end

    def system_prompt
      <<~PROMPT
        You are an AI assistant that helps summarize video transcripts.
        Try to comprehend and infer meaning of the messages in the transcript.
        Timeline should be as comprehensive as possible.
        EXTREMELY important: check metadata for timestamps and topics as a reference.
        EXTREMELY important: generate at least a 10 topic timeline.
        EXTREMELY important: if metadata topics are less than 10, fill in gaps between the topics.
        EXTREMELY important: if metadata topics are more than 10, you can definitely exceed the 10 topics, and use the metadata topics as is, make sure to correct timestamps format to "hh:mm:ss".
        EXTREMELY important: timestamps should be roughly evenly spaced and distributed.
        EXTREMELY important: timestamps should not exceed video duration.
        EXTREMELY important: timestamps format is "hh:mm:ss".
        Once you have generated the timeline, go over the takeaways again and add any missing points.
        Double check that the timestamps you provide are correct.
        Ignore any advertising or promotional information that is not relevant to the transcript.
        In some videos, the first section is usually a summary of what to expect in the video. If that is the case, be very careful not to base the timestamps of where the topics start on the first section if that is the case.
        Your response must be in valid JSON format.

        Make sure your response is a valid JSON object with no trailing commas.
        Do not include any explanatory text outside the JSON structure.
        The response must contain exactly these fields:
        {
          "tldr": "A brief tldr here, mentioning speakers if possible",
          "contents": [
            {"timestamp": "00:00:30", "topic": "here you mention the topic.", "takeaway": "here you provide a paragraph of the takeways in this segment."},
          ],
          "summary": "Detailed summary focusing on searching keywords, minmum 200 words blah blah blah with. blah blah blah. blah blah blah."
        }
      PROMPT
    end

    # This method is called by the async job processor
    # @param transcript [String] The video transcript
    # @param metadata [Hash] The video metadata
    # @return [Hash] Summary data or error message
    def process_task(video_id, transcript, metadata)
      return { success: false, error: "Video is too short" } if transcript.length < 100

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
        result = JSON.parse(content, symbolize_names: true)

        unless result[:tldr] && result[:contents] && result[:summary]
          return { success: false, error: "Missing required fields in response" }
        end

        {
          success: true,
          tldr: result[:tldr],
          contents: result[:contents],
          summary: result[:summary]
        }
      rescue JSON::ParserError => e
        log_error "JSON parsing error", context: {
          error: e.message,
          backtrace: e.full_message,
          content: content
        }
        { success: false, error: "Failed to parse summary: #{e.message}" }
      rescue => e
        log_error "Summary error", context: {
          error: e.message,
          backtrace: e.full_message,
          content: content
        }
        { success: false, error: "Failed to generate summary: #{e.message}" }
      end
    end
  end
end
