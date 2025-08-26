📁 app/
├── 🎮 controllers/
│   ├── application_controller.rb
│   │   └── Concerns:
│   │       ├── authentication.rb
│   │       └── request_traceable.rb
│   │
│   ├── summaries_controller.rb
│   │   └── Services:
│   │       ├── Youtube::YoutubeVideoMetadataService
│   │       ├── Youtube::YoutubeVideoTranscriptService
│   │       ├── Ai::LlmSummaryService
│   │       └── UserServices::UserDataService
│   │   └── Actions:
│   │       ├── show - Display video summary with metadata and transcript
│   │       ├── index - List user's saved video summaries with pagination
│   │       ├── create_from_url - Create summary from YouTube URL
│   │       ├── expand_takeaway - Expand specific takeaway with AI
│   │       └── remove_from_user - Remove summary from user's saved list
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
│   ├── async_job_processor.rb
│   │   └── ❌ REMOVED - Unused async processing pattern
│   │
│   └── cleanup_job.rb
│       └── Services:
│           └── Storage::MongoStorageService
│
├── 🛠️ services/
│   ├── cache/
│   │   ├── base_cache_service.rb
│   │   └── mongo_cache_service.rb - MongoDB-based caching with retry mechanism
│   │
│   ├── ai/
│   │   ├── chat_gpt_service.rb
│   │   ├── chat_thread_service.rb
│   │   ├── llm_summary_service.rb
│   │   ├── llm_takeaway_expander_service.rb
│   │   ├── clients/
│   │   │   ├── base_client.rb
│   │   │   ├── openai_client.rb
│   │   │   └── gemini_client.rb
│   │   ├── llm_service_base.rb
│   │   └── prompts/
│   │       └── prompt_store.rb
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

## Python Script Timeout Improvements

The `PythonScriptable` concern has been enhanced to prevent hanging issues:

- **Non-blocking I/O**: Uses `IO.select` and `read_nonblock` to prevent hanging on stdout/stderr reads
- **Aggressive timeouts**: YouTube transcript service uses 15-second timeout (configurable via `YOUTUBE_TRANSCRIPT_TIMEOUT`)
- **Process cleanup**: Improved process termination with TERM followed by KILL signals
- **Resource management**: Proper cleanup of file descriptors and process trees
- **Error handling**: Comprehensive error handling with process cleanup on failures

## Service Dependencies

All services now use the `Persistable` concern for consistent data storage operations:

- **AI Services**: `LlmSummaryService`, `LlmTakeawayExpanderService`
- **YouTube Services**: `YoutubeVideoMetadataService`, `YoutubeVideoTranscriptService`, `YoutubeChannelService`  
- **User Services**: `UserDataService`

This unified approach ensures consistent behavior, error handling, and API across the entire application using MongoDB as the primary data store.