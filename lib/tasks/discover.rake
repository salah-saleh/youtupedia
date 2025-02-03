namespace :discover do
  desc "Generate summaries for the latest video from each master user's channel"
  task process_latest_videos: :environment do
    # Get all channels from master user
    channel_names = UserServices::UserDataService.user_items("master", :channels)
    
    puts "--> Found #{channel_names.size} channels to process"
    
    channel_names.each do |channel_name|
      begin
        puts "\n--> Processing channel: #{channel_name}"
        
        # Get channel metadata
        channel = Youtube::YoutubeChannelService.fetch_channel_metadata(channel_name)
        unless channel[:success]
          puts "--> Failed to fetch channel metadata for #{channel_name}: #{channel[:error]}"
          next
        end
        
        # Get latest video
        response = Youtube::YoutubeChannelService.fetch_channel_videos(
          channel_name,
          channel[:channel_id],
          1 # Only get the latest video
        )
        
        unless response[:success] && response[:videos].any?
          puts "--> No videos found for channel #{channel_name}"
          next
        end
        
        latest_video = response[:videos].first
        video_id = latest_video[:video_id]
        
        puts "--> Processing video: #{latest_video[:title]} (#{video_id})"
        
        # Check if we already have a summary
        existing_summary = Ai::LlmSummaryService.fetch_summary(video_id)
        if existing_summary&.dig(:success)
          puts "--> Summary already exists for video #{video_id}"
          UserServices::UserDataService.add_item("master", :summaries_sponsered, video_id)
          next
        end
        
        # Process the summary synchronously
        puts "--> Generating summary..."
        
        # Get metadata
        metadata = Youtube::YoutubeVideoMetadataService.fetch_metadata(video_id)
        unless metadata[:success]
          puts "--> Failed to fetch metadata for video #{video_id}: #{metadata[:error]}"
          next
        end
        
        # Get transcript
        transcript_service = Youtube::YoutubeVideoTranscriptService.new
        transcript = transcript_service.process_task(video_id)
        unless transcript[:success]
          puts "--> Failed to get transcript for video #{video_id}: #{transcript[:error]}"
          next
        end
        
        # Cache the transcript
        Youtube::YoutubeVideoTranscriptService.write_cached(video_id, transcript, expires_in: nil)
        
        # Generate summary
        summary_service = Ai::LlmSummaryService.new(:gemini)
        result = summary_service.process_task(video_id, transcript[:transcript_full], metadata)
        unless result[:success]
          puts "--> Failed to generate summary for video #{video_id}: #{result[:error]}"
          next
        end
        
        # Cache the summary
        Ai::LlmSummaryService.write_cached(video_id, result, expires_in: nil)
        
        # Add to master's summaries list
        UserServices::UserDataService.add_item("master", :summaries_sponsered, video_id)
        
        puts "--> Successfully processed video #{video_id}"
        
      rescue => e
        puts "--> Error processing channel #{channel_name}: #{e.message}"
        puts e.backtrace.join("\n")
      end
    end
    
    puts "\n--> Discover task completed!"
  end
end
