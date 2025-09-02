# Audio Storage Migration Task
#
# This task migrates existing audio files from MongoDB storage to Active Storage (GCS).
# It handles the transition from storing base64 audio content in MongoDB documents
# to storing files in Google Cloud Storage with metadata references in MongoDB.
#
# Usage:
#   rails audio_migration:migrate_to_active_storage
#   rails audio_migration:cleanup_old_audio_content
#   rails audio_migration:verify_migration

namespace :audio_migration do
  desc "Migrate existing audio files from MongoDB to Active Storage"
  task migrate_to_active_storage: :environment do
    puts "🎵 Starting audio migration to Active Storage..."
    
    # Get all audio documents from MongoDB
    storage_service = Storage::MongoStorageService.new("tts_audio")
    all_keys = storage_service.all_keys
    
    puts "📊 Found #{all_keys.length} audio documents to migrate"
    
    migrated_count = 0
    failed_count = 0
    skipped_count = 0
    
    all_keys.each do |video_id|
      begin
        puts "🔄 Processing video: #{video_id}"
        
        # Fetch existing audio data
        audio_data = storage_service.read(video_id)
        
        unless audio_data&.dig(:success)
          puts "⏭️  Skipping failed audio for #{video_id}"
          skipped_count += 1
          next
        end
        
        # Check if already migrated (has blob_id)
        if audio_data[:blob_id].present?
          puts "✅ Already migrated: #{video_id}"
          skipped_count += 1
          next
        end
        
        # Check if audio_content exists
        unless audio_data[:audio_content].present?
          puts "⚠️  No audio content for #{video_id}, skipping"
          skipped_count += 1
          next
        end
        
        # Create Active Storage blob
        blob = create_audio_blob_from_existing_data(video_id, audio_data)
        
        # Update the document with blob_id and remove audio_content
        updated_data = audio_data.dup
        updated_data[:blob_id] = blob.id
        updated_data[:audio_url] = Rails.application.routes.url_helpers.rails_blob_path(blob, only_path: true)
        updated_data.delete(:audio_content) # Remove the large base64 content
        
        # Save updated document
        storage_service.write(video_id, updated_data)
        
        puts "✅ Migrated: #{video_id} -> blob_id: #{blob.id}"
        migrated_count += 1
        
      rescue => e
        puts "❌ Failed to migrate #{video_id}: #{e.message}"
        failed_count += 1
      end
    end
    
    puts "\n📈 Migration Summary:"
    puts "  ✅ Migrated: #{migrated_count}"
    puts "  ⏭️  Skipped: #{skipped_count}"
    puts "  ❌ Failed: #{failed_count}"
    puts "  📊 Total: #{all_keys.length}"
    
    if failed_count > 0
      puts "\n⚠️  Some migrations failed. Check the logs above for details."
    else
      puts "\n🎉 All audio files successfully migrated to Active Storage!"
    end
  end
  
  desc "Clean up old audio_content from MongoDB documents"
  task cleanup_old_audio_content: :environment do
    puts "🧹 Cleaning up old audio_content from MongoDB..."
    
    storage_service = Storage::MongoStorageService.new("tts_audio")
    all_keys = storage_service.all_keys
    
    cleaned_count = 0
    
    all_keys.each do |video_id|
      begin
        audio_data = storage_service.read(video_id)
        
        # Only clean up if we have blob_id (migrated) and still have audio_content
        if audio_data&.dig(:success) && audio_data[:blob_id].present? && audio_data[:audio_content].present?
          updated_data = audio_data.dup
          updated_data.delete(:audio_content)
          
          storage_service.write(video_id, updated_data)
          puts "🧹 Cleaned up audio_content for: #{video_id}"
          cleaned_count += 1
        end
        
      rescue => e
        puts "❌ Failed to clean up #{video_id}: #{e.message}"
      end
    end
    
    puts "\n📈 Cleanup Summary:"
    puts "  🧹 Cleaned: #{cleaned_count} documents"
  end
  
  desc "Verify migration by checking blob existence and accessibility"
  task verify_migration: :environment do
    puts "🔍 Verifying audio migration..."
    
    storage_service = Storage::MongoStorageService.new("tts_audio")
    all_keys = storage_service.all_keys
    
    verified_count = 0
    failed_count = 0
    
    all_keys.each do |video_id|
      begin
        audio_data = storage_service.read(video_id)
        
        unless audio_data&.dig(:success)
          puts "⏭️  Skipping failed audio for #{video_id}"
          next
        end
        
        if audio_data[:blob_id].present?
          # Verify blob exists
          blob = ActiveStorage::Blob.find(audio_data[:blob_id])
          
          # Verify blob is accessible
          if blob.service.exist?(blob.key)
            puts "✅ Verified: #{video_id} -> blob_id: #{blob.id}"
            verified_count += 1
          else
            puts "❌ Blob not accessible: #{video_id} -> blob_id: #{blob.id}"
            failed_count += 1
          end
        else
          puts "⚠️  No blob_id for: #{video_id}"
          failed_count += 1
        end
        
      rescue ActiveRecord::RecordNotFound
        puts "❌ Blob not found for: #{video_id}"
        failed_count += 1
      rescue => e
        puts "❌ Verification failed for #{video_id}: #{e.message}"
        failed_count += 1
      end
    end
    
    puts "\n📈 Verification Summary:"
    puts "  ✅ Verified: #{verified_count}"
    puts "  ❌ Failed: #{failed_count}"
    puts "  📊 Total: #{all_keys.length}"
  end
  
  private
  
  # Creates an Active Storage blob from existing MongoDB audio data
  def create_audio_blob_from_existing_data(video_id, audio_data)
    # Decode base64 content to binary
    audio_content = Base64.strict_decode64(audio_data[:audio_content])
    mime_type = audio_data[:mime_type] || "audio/wav"
    
    # Generate filename with appropriate extension
    file_extension = case mime_type
                    when /wav/ then "wav"
                    when /mp3/ then "mp3"
                    when /mpeg/ then "mp3"
                    when /ogg/ then "ogg"
                    else "wav"
                    end
    
    filename = "#{video_id}.#{file_extension}"
    
    puts "  📁 Creating blob: #{filename} (#{(audio_content.length / 1024.0 / 1024.0).round(2)} MB)"
    
    # Create and upload blob
    blob = ActiveStorage::Blob.create_and_upload!(
      io: StringIO.new(audio_content),
      filename: filename,
      content_type: mime_type,
      metadata: {
        video_id: video_id,
        migrated_at: Time.current.iso8601,
        original_generated_at: audio_data[:generated_at]&.iso8601,
        service: "tts_migration"
      }
    )
    
    blob
  end
end
