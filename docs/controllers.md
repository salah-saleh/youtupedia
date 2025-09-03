📁 app/
├── 🎮 controllers/
│   ├── application_controller.rb
│   │   └── Concerns:
│   │       ├── authentication.rb
│   │       └── request_traceable.rb
│   │
│   ├── summaries_controller.rb
│   │   └── Concerns:
│   │       ├── YoutubeUrlHelper
│   │       ├── SummaryDataHelper
│   │       ├── VideoSummariesHelper
│   │       ├── Paginatable
│   │       └── AudioResponseHandler (NEW - standardized audio response handling)
│   │   └── Services:
│   │       ├── Youtube::YoutubeVideoMetadataService
│   │       ├── Youtube::YoutubeVideoTranscriptService
│   │       ├── Ai::LlmSummaryService
│   │       ├── Ai::TtsService
│   │       ├── AudioGenerationService (NEW - business logic for audio generation)
│   │       └── UserServices::UserDataService
│   │   └── Actions:
│   │       ├── show - Display video summary with metadata and transcript
│   │       ├── index - List user's saved video summaries with pagination
│   │       ├── create_from_url - Create summary from YouTube URL
│   │       ├── expand_takeaway - Expand specific takeaway with AI (uses Turbo Streams)
│   │       ├── generate_audio - Generate audio summary using Gemini TTS (SIMPLIFIED - now uses Rails forms with Turbo Streams)
│   │       └── remove_from_user - Remove summary from user's saved list (uses Turbo Streams)
│   │
│   ├── audio_controller.rb
│   │   └── Concerns:
│   │       └── AudioResponseHandler (NEW - standardized audio response handling)
│   │   └── Actions:
│   │       └── show - Serve generated TTS audio files by video ID (REFACTORED - now uses Active Storage redirects)
│   │   └── Response Pattern:
│   │       ├── Success: Redirects to Active Storage blob URL (serves from GCS in production)
│   │       └── Errors: Uses standardized audio error responses via AudioResponseHandler
│   │   └── Storage Architecture:
│   │       ├── Metadata: Stored in MongoDB (without audio content)
│   │       ├── Audio Files: Stored in Google Cloud Storage via Active Storage
│   │       └── Access: Direct redirect to GCS URLs for optimal performance
│   │
│   ├── channels_controller.rb
│   │   └── Services:
│   │       ├── Youtube::YoutubeChannelService
│   │       └── Storage::MongoStorageService
│   │   └── Actions:
│   │       ├── index - List user's subscribed channels with pagination
│   │       ├── show - Display channel details and videos
│   │       ├── create_from_url - Add channel from YouTube URL
│   │       └── remove_from_user - Remove channel from user's saved list
│   │
│   │   Flow (show):
│   │   - Reads `@channel_name` from `params[:id]`
│   │   - Fetches channel metadata via `Youtube::YoutubeChannelService.fetch_channel_metadata(@channel_name)`
│   │     - Metadata now includes `uploads_playlist_id` sourced from `channels.list(contentDetails)`
│   │   - Fetches videos via:
│   │     - `Youtube::YoutubeChannelService.fetch_channel_videos(@channel_name, @channel[:channel_id], @per_page, @current_token)` when no query
│   │     - `Youtube::YoutubeChannelService.fetch_channel_videos_search(@channel_name, @channel[:channel_id], params[:q], @per_page, @current_token)` when `params[:q]` present (sorted by relevance)
│   │     - Under the hood, this uses the channel's uploads playlist and `playlistItems.list` for reliable pagination tokens
│   │   - Sets `@next_token` and `@prev_token` for the pagination component
│   │
│   ├── youtube_urls_controller.rb
│   │   └── Services:
│   │       ├── Youtube::YoutubeVideoMetadataService
│   │       └── Youtube::YoutubeVideoTranscriptService
│   │
│   ├── search_controller.rb
│   │   └── Services:
│   │       └── SearchableConcern
│   │
│   └── dev/
│       └── users_controller.rb
│
├── 🔧 helpers/
│   ├── application_helper.rb
│   │   └── Methods:
│   │       ├── render_icon
│   │       └── format_timestamp
│   │
│   ├── summary_helper.rb
│   │   └── Methods:
│   │       ├── format_duration
│   │       └── format_view_count
│   │
│   └── channel_helper.rb
│       └── Methods:
│           └── format_subscriber_count
│
├── 🎮 javascript/controllers/
│   ├── remove_item_controller.js
│   │   └── Features:
│   │       ├── Smooth remove animations with permanent deleted state
│   │       ├── Blur effect and overlay that persists until page refresh
│   │       ├── Maintains grid layout by keeping items in deleted state
│   │       └── Success feedback with button state changes
│   │   └── Methods:
│   │       ├── remove - Handles remove button click with loading state
│   │       ├── showDeletedState - Shows blurred deleted state with overlay
│   │       └── checkEmptyState - Shows empty state when grid is empty
│   │
│   └── ❌ REMOVED - audio_controller.js (simplified to use Rails forms with Turbo Streams)
│
├── 🔄 jobs/
│   ├── application_job.rb
│   │   └── Concerns:
│   │       └── job_schedulable.rb - Prevents duplicate job execution
│   │
│   ├── summary_job.rb
│   │   └── Services:
│   │       ├── Youtube::YoutubeVideoMetadataService
│   │       ├── Youtube::YoutubeVideoTranscriptService
│   │       ├── Ai::LlmSummaryService
│   │       └── Storage::MongoStorageService
│   │
│   ├── audio_summary_job.rb
│   │   └── Services:
│   │       ├── Ai::LlmSummaryService
│   │       ├── Ai::TtsService
│   │       └── Turbo::StreamsChannel
│   │
│   ├── audio_upload_job.rb (NEW)
│   │   └── Services:
│   │       ├── Ai::TtsService
│   │       └── ActiveStorage::Blob
│   │   └── Features:
│   │       ├── Background upload of audio files to Google Cloud Storage
│   │       ├── Prevents base64 audio data from corrupting logs (log_arguments? = false)
│   │       ├── Updates metadata with permanent storage information
│   │       └── Cleans up temporary cache after successful upload
│   │
│   ├── async_job_processor.rb
│   │   └── ❌ REMOVED - Unused async processing pattern
│   │
│   └── cleanup_job.rb
│       └── Services:
│           └── Storage::MongoStorageService
│
├── 🛠️ services/
│   ├── audio_generation_service.rb - (NEW) Business logic for audio generation and job scheduling
│   │
│   ├── cache/
│   │   ├── base_cache_service.rb
│   │   └── mongo_cache_service.rb - MongoDB-based caching with retry mechanism
│   │
│   ├── ai/
│   │   ├── chat_gpt_service.rb
│   │   ├── chat_thread_service.rb
│   │   ├── llm_summary_service.rb - Refactored to use LlmServiceBase directly
│   │   ├── llm_takeaway_expander_service.rb - Refactored to use LlmServiceBase directly
│   │   ├── llm_service_base.rb - Common LLM functionality (clients, prompts, response handling, task processing)
│   │   ├── tts_service.rb - (ENHANCED) Text-to-speech service with token usage tracking
│   │   ├── prompts/
│   │   │   └── prompt_store.rb
│   │   └── clients/
│   │       ├── base_client.rb - Base interface for AI clients with video_id and operation_type tracking
│   │       ├── openai_client.rb - OpenAI GPT-4 client implementation
│   │       └── gemini_client.rb - Gemini client with token consumption tracking and detailed logging
│   │
│   ├── youtube/
│   │   ├── youtube_base_service.rb
│   │   ├── youtube_video_metadata_service.rb
│   │   ├── youtube_video_transcript_service.rb
│   │   └── youtube_channel_service.rb
│   │
│   ├── user_services/
│   │   └── user_data_service.rb
│   │
│   ├── search/
│   │   ├── channel_search_service.rb
│   │   └── video_search_service.rb
│   │
│   ├── lock/
│   │   └── request_lock_service.rb - MongoDB-based request locking
│   │
│   └── ❌ REMOVED - Unused async processing pattern
│
├── 📱 views/
│   ├── summaries/
│   │   ├── show.html.erb
│   │   └── index.html.erb
│   │
│   ├── channels/
│   │   ├── show.html.erb
│   │   └── index.html.erb
│   │
│   └── shared/
│       ├── _video_card.html.erb
│       ├── _channel_card.html.erb
│       └── _pagination.html.erb
│
└── 🔧 concerns/
    ├── authentication.rb - User authentication and session management
    ├── audio_response_handler.rb - (NEW) Standardized audio response handling and validation
    ├── captcha_verifiable.rb - reCAPTCHA verification
    ├── dev_route_protection.rb - Admin route protection
    ├── paginatable.rb - Pagination functionality
    ├── python_scriptable.rb - Python script execution with timeout protection
    ├── request_lockable.rb - Request locking for concurrent operations
    ├── request_traceable.rb - Request tracking and logging
    ├── summary_data_helper.rb - Summary data building
    ├── video_summaries_helper.rb - Video summary handling
    └── youtube_url_helper.rb - YouTube URL parsing

## Data Storage Architecture

The application uses a standardized MongoDB-based data persistence approach with consistent APIs:

- **Persistable Concern** - Unified data storage interface across all services
- **Storage::MongoStorageService** - MongoDB storage with retry mechanism and error handling
- **Consistent API** - All services use `fetch_stored`, `write_stored`, `read_stored`, `stored?`, `delete_stored`
- **Namespace Isolation** - Each service has its own storage namespace with support for custom namespaces
- **Force Execution Support** - Ability to bypass storage and regenerate data when needed

## Key Changes

1. **Added Persistable concern** - Unified data storage interface with consistent API across all services
2. **Removed AsyncProcessable concern** - No more unused async processing pattern  
3. **Standardized storage operations** - All services use the same storage methods through Persistable
4. **Improved error handling** - Enhanced retry mechanism and graceful failure handling
5. **Clearer naming** - Renamed from "cache" to "storage" to reflect MongoDB as primary data store
6. **Simplified job scheduling** - JobSchedulable uses Rails.cache for duplicate prevention
7. **Request locking** - RequestLockService uses Rails.cache for distributed locks
8. **Enhanced Python script execution** - PythonScriptable concern now uses non-blocking I/O with proper timeout protection
9. **Cleaner architecture** - Consistent patterns reduce code duplication and improve maintainability
10. **Enhanced AI client tracking** - Added comprehensive token consumption tracking and model configuration logging for Gemini API calls
11. **Added Audio Summary Feature** - New TTS service using Gemini 2.5 Preview TTS with Algenib voice for converting text summaries to audio
12. **Turbo Stream Response Consistency** - Standardized all AJAX-like actions to use Turbo Streams instead of JSON responses for better Rails/Hotwire integration
13. **Audio Controller Refactoring** - (NEW) Extracted common audio response patterns into AudioResponseHandler concern
14. **Audio Generation Service** - (NEW) Created dedicated service for audio generation business logic
15. **TTS Token Tracking** - (NEW) Added comprehensive token usage tracking to TTS operations with specialized estimation
16. **Common Token Interface** - (NEW) Created GeminiTokenTracker base class for consistent token tracking across all Gemini clients
17. **AudioUploadJob Logging Fix** - (NEW) Fixed log corruption issue by preventing base64 audio data from being logged in job arguments and cache keys
18. **Audio Generation Simplification** - (NEW) Removed JavaScript controller in favor of Rails forms with Turbo Streams for better Rails 8 integration

## Python Script Timeout Improvements

The `PythonScriptable` concern has been enhanced to prevent hanging issues:

- **Non-blocking I/O**: Uses `IO.select` and `read_nonblock` to prevent hanging on stdout/stderr reads
- **Aggressive timeouts**: YouTube transcript service uses 15-second timeout (configurable via `YOUTUBE_TRANSCRIPT_TIMEOUT`)
- **Process cleanup**: Improved process termination with TERM followed by KILL signals
- **Resource management**: Proper cleanup of file descriptors and process trees
- **Error handling**: Comprehensive error handling with process cleanup on failures

## AI Client Token Tracking

The AI services now include comprehensive tracking and logging for better monitoring and cost analysis:

- **Token Consumption Tracking**: Estimates input/output tokens for Gemini API calls using character-based approximation
- **Model Configuration Logging**: Logs all generation parameters (temperature, top_p, top_k, max_output_tokens)
- **Video ID Association**: Links API calls to specific video IDs for better traceability
- **Operation Type Tracking**: Categorizes API calls (summary_generation, takeaway_expansion, tts_generation)
- **Detailed Logging**: Comprehensive logging before and after each API call with timing and token information
- **Python Script Integration**: Enhanced Python scripts return token usage estimates and model configuration details
- **TTS Token Tracking**: Specialized token estimation for Text-to-Speech operations including processing overhead

### Supported Operations:
- **Summary Generation**: `LlmSummaryService` with operation_type "summary_generation"
- **Takeaway Expansion**: `LlmTakeawayExpanderService` with operation_type "takeaway_expansion"
- **TTS Generation**: `TtsService` with operation_type "tts_generation" (NEW)

### TTS Token Estimation:
TTS operations use a specialized token estimation that considers:
- **Input Tokens**: Based on text length (similar to text generation)
- **Processing Tokens**: Additional tokens for voice synthesis processing
- **Voice Complexity**: Different voices may have different token costs
- **Duration Factor**: Longer audio may require more processing tokens

### Logging Output Example:
```
[GeminiClient] Gemini API call starting | script_name: gemini_summary_client.py, video_id: abc123, operation_type: summary_generation, model: gemini-2.0-flash, estimated_input_tokens: 1250, generation_config: {...}

[GeminiClient] Gemini API call completed successfully | script_name: gemini_summary_client.py, video_id: abc123, operation_type: summary_generation, model: gemini-2.0-flash, elapsed_seconds: 2.345, success: true, input_tokens: 1250, output_tokens: 890, total_tokens: 2140

[GeminiTtsClient] Gemini API call starting | operation_type: tts_generation, video_id: abc123, model: gemini-2.5-flash-preview-tts, voice_name: Algenib, estimated_input_tokens: 500, estimated_total_tokens: 750

[GeminiTtsClient] Gemini API call completed | operation_type: tts_generation, video_id: abc123, model: gemini-2.5-flash-preview-tts, elapsed_seconds: 8.234, success: true, input_tokens: 500, processing_tokens: 250, total_tokens: 750
```

## Audio Storage Architecture (NEW)

The application now uses a hybrid storage approach for audio files:

### Storage Strategy:
- **Metadata**: Stored in MongoDB (video_id, voice, duration, token_usage, etc.)
- **Audio Files**: Stored in Google Cloud Storage via Active Storage
- **Access**: Direct redirect to GCS URLs for optimal performance

### Benefits:
- **Scalability**: No MongoDB document size limits (16MB)
- **Performance**: Direct file serving from GCS CDN
- **Cost**: ~90% cheaper than database storage
- **Backup**: Smaller database backups, files in GCS
- **CDN**: Automatic caching and global distribution

### Migration:
- **Existing Files**: Use `rails audio_migration:migrate_to_active_storage`
- **Cleanup**: Use `rails audio_migration:cleanup_old_audio_content`
- **Verification**: Use `rails audio_migration:verify_migration`

### Configuration:
```yaml
# config/storage.yml
google:
  service: GCS
  project: <%= Rails.application.credentials.dig(:gcs, :project_id) %>
  credentials: <%= Rails.application.credentials.dig(:gcs, :keyfile_path) %>
  bucket: youtupedia-audio-files-<%= Rails.env %>
```

## Service Dependencies

All services now use the `Persistable` concern for consistent data storage operations:

- **AI Services**: `LlmSummaryService`, `LlmTakeawayExpanderService`, `TtsService` (with Active Storage)
- **YouTube Services**: `YoutubeVideoMetadataService`, `YoutubeVideoTranscriptService`, `YoutubeChannelService`  
- **User Services**: `UserDataService`

This unified approach ensures consistent behavior, error handling, and API across the entire application using MongoDB as the primary data store for metadata and Active Storage for file assets.

## Critical Production Fixes

### Python Script Timeout Resolution (December 2024)
The application experienced hanging issues in Cloud Run production where Python scripts (specifically `youtube_transcript.py`) would hang indefinitely despite timeout mechanisms. This was resolved with major improvements to the `PythonScriptable` concern:

#### Problem Analysis
- Production logs showed ~40-second hangs despite 5-second timeouts
- Standard `Timeout.timeout` was ineffective with blocking I/O operations
- Process termination signals were not working reliably in Cloud Run containers

#### Solution Implementation
1. **Removed dependency on `Timeout.timeout`** - Replaced with custom timeout logic
2. **Implemented aggressive timeout monitoring** - Separate monitoring thread actively kills processes
3. **Enhanced process termination with 4-strategy approach**:
   - Strategy 1: TERM signal to process group (graceful)
   - Strategy 2: KILL signal to process group (forceful)
   - Strategy 3: Direct signals bypassing process group
   - Strategy 4: System-level kill commands (last resort)
4. **Added comprehensive logging** - Track every termination attempt with timing
5. **Non-blocking I/O implementation** - Prevents hanging on stdout/stderr reads

#### Key Components
- `read_with_aggressive_timeout()` - New method with active monitoring
- Enhanced `kill_process_tree()` - Multi-strategy process termination
- Detailed process lifecycle logging for production debugging

This ensures Python scripts are terminated within seconds rather than hanging for 40+ seconds in production.

## JobSchedulable Hash-Based Cache Key Strategy (December 2024)

The `JobSchedulable` concern has been completely rewritten to use hash-based cache keys, solving log corruption issues efficiently:

### Problem Analysis
- Jobs with large arguments (like base64 audio content) were corrupting logs
- Cache keys included full argument values, causing massive log entries
- `AudioUploadJob` was creating cache keys with entire base64 audio strings
- The cache key itself became the problem, not just the logging

### Solution Implementation
1. **SHA256 Hash-Based Keys** - All job arguments are hashed using SHA256
2. **Consistent Short Keys** - Cache keys are always predictable length regardless of argument size
3. **Preserved Uniqueness** - Hash ensures different arguments produce different cache keys
4. **Efficient Performance** - Hash calculation is fast and memory-efficient

### Key Components
- `build_job_cache_key(*args)` - Uses `Digest::SHA256.hexdigest(args.to_json)`
- Enhanced `cleanup_job_cache` - All cache keys are now short and clean
- Updated `schedule` and `clear_job_cache` - Use hash-based cache key generation
- **No special cases needed** - Works uniformly for all job types

### Cache Key Format
All jobs now use: `job_name:sha256_hash_of_arguments`

### Example Output
```
# Before (corrupted logs):
Starting job with cache key: audio_upload_job:2_6ad9URawc:UklGRjJ3MA... [massive base64 string]

# After (clean logs):
Starting job with cache key: audio_upload_job:a1b2c3d4e5f6789012345678901234567890abcdef1234567890abcdef123456
```

### Benefits
- **Log Cleanliness**: All cache keys are exactly 64 characters (SHA256 hex)
- **Performance**: No string concatenation of large arguments
- **Memory Efficiency**: No large strings stored in memory for cache keys
- **Universal Solution**: Works for any job with any argument size
- **Collision Resistance**: SHA256 provides excellent uniqueness guarantees

This provides a robust, scalable solution that handles any job argument size efficiently.