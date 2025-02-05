namespace :discover do
  desc "Generate summaries for the latest video from each master user's channel"
  task process_latest_videos: :environment do
    # Get all channels from master user
    channel_names = UserServices::UserDataService.user_items("master", :channels_sponsered)
    
    puts "--> Found #{channel_names.size} channels to process"
    
    # Track memory usage
    initial_memory = GetProcessMem.new.mb
    puts "--> Initial memory usage: #{initial_memory.round(2)} MB"
    
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
        
        # Get transcript with timeout handling and retry
        transcript = nil
        transcript_attempts = 0
        max_transcript_attempts = 2  # One initial try + one retry
        transcript_timeout = 10  # 10 seconds timeout for transcript
        
        begin
          Timeout.timeout(transcript_timeout) do
            transcript_service = Youtube::YoutubeVideoTranscriptService.new
            transcript = transcript_service.process_task(video_id)
            
            unless transcript[:success]
              if transcript_attempts < max_transcript_attempts - 1
                transcript_attempts += 1
                puts "--> Retrying transcript fetch for video #{video_id} (attempt #{transcript_attempts + 1}/#{max_transcript_attempts})"
                sleep 2  # Brief pause before retry
                redo  # Try again from the beginning of the begin block
              else
                puts "--> Failed to get transcript for video #{video_id} after #{max_transcript_attempts} attempts: #{transcript[:error]}"
                next
              end
            end
            
            # Cache the transcript if successful
            Youtube::YoutubeVideoTranscriptService.write_cached(video_id, transcript, expires_in: nil)
          end
        rescue Timeout::Error
          puts "--> Timeout while fetching transcript for video #{video_id} after #{transcript_timeout} seconds."
          if transcript_attempts < max_transcript_attempts - 1
            transcript_attempts += 1
            puts "--> Retrying transcript fetch (attempt #{transcript_attempts + 1}/#{max_transcript_attempts})"
            sleep 2  # Brief pause before retry
            retry
          else
            puts "--> Moving to next video after #{max_transcript_attempts} attempts"
            next
          end
        end

        # Generate summary with separate timeout
        summary_timeout = 60  # 60 seconds timeout for summary generation
        begin
          Timeout.timeout(summary_timeout) do
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
          end
        rescue Timeout::Error
          puts "--> Timeout while generating summary for video #{video_id} after #{summary_timeout} seconds. Moving to next video."
          next
        end
        
        # Log memory usage after each video
        current_memory = GetProcessMem.new.mb
        memory_increase = current_memory - initial_memory
        puts "--> Current memory usage: #{current_memory.round(2)} MB (#{memory_increase.round(2)} MB increase)"
        
        # Force garbage collection if memory increase is significant
        if memory_increase > 25 # If memory increased by more than 25MB
          GC.start
          puts "--> Forced garbage collection"
          current_memory = GetProcessMem.new.mb
          puts "--> Memory after GC: #{current_memory.round(2)} MB"
        end
        
      rescue => e
        puts "--> Error processing channel #{channel_name}: #{e.message}"
        puts e.backtrace.join("\n")
      end
    end
    
    # Final memory report
    final_memory = GetProcessMem.new.mb
    total_increase = final_memory - initial_memory
    puts "\n--> Memory Usage Report:"
    puts "  Initial: #{initial_memory.round(2)} MB"
    puts "  Final: #{final_memory.round(2)} MB"
    puts "  Total Increase: #{total_increase.round(2)} MB"
    
    puts "\n--> Discover task completed!"
  end
end
