class ChatGptService < BaseAsyncService
  def perform(transcript)
    return { success: false, error: "Transcript is too short" } if transcript.length < 100

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
            content: "Please summarize this video transcript: #{transcript}"
          }
        ],
        temperature: 0.7
      }
    )

    content = response.dig("choices", 0, "message", "content")
    return { success: false, error: "No content received" } unless content

    result = JSON.parse(content)
    {
      success: true,
      tldr: result["tldr"],
      takeaways: result["takeaways"],
      tags: result["tags"],
      summary: result["summary"]
    }
  rescue => e
    Rails.logger.error "Summary Error: #{e.message}"
    { success: false, error: "Failed to generate summary: #{e.message}" }
  end

  def answer_question(video_id, question, transcript)
    client = OpenAI::Client.new(access_token: ENV["OPENAI_API_KEY"])
    thread_data = ChatThreadService.create_or_load_thread(video_id)

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
        content: "Here is the transcript to analyze: #{transcript}"
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

    ChatThreadService.save_message(video_id, "user", question)
    ChatThreadService.save_message(video_id, "assistant", content)

    { success: true, answer: content }
  rescue => e
    Rails.logger.error "Chat GPT Error: #{e.message}"
    { success: false, error: "Failed to process question: #{e.message}" }
  end

  private

  def system_prompt
    <<~PROMPT
      You are an AI assistant that helps summarize video transcripts.
      Please analyze the transcript and provide:
      1. A brief TLDR
      2. Key takeaways with timestamps
      3. Important tags/topics with timestamps
      4. A detailed summary that references timestamps

      Format your response as a JSON object with the following structure (Don't include any other text, don't include the word JSON):
      {
        "tldr": "Brief summary here",
        "takeaways": [
          { "timestamp": 123, "content": "Key point 1" }
        ],
        "tags": [
          { "timestamp": 123, "tag": "Topic 1" }
        ],
        "summary": "Detailed summary with (123) timestamp references"
      }
    PROMPT
  end
end
