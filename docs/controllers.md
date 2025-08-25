📁 app/
├── 🎮 controllers/
│   ├── application_controller.rb
│   │   └── Concerns:
│   │       ├── authentication.rb
│   │       └── error_handling.rb
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
│   │       ├── YoutubeChannelService
│   │       └── MongoCacheService
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
│   │       ├── YoutubeVideoMetadataService
│   │       └── YoutubeVideoTranscriptService
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
│   ├── summary_generation_job.rb
│   │   └── Services:
│   │       ├── ChatGptService
│   │       └── MongoCacheService
│   │
│   ├── transcript_fetch_job.rb
│   │   └── Services:
│   │       └── YoutubeVideoTranscriptService
│   │
│   ├── channel_sync_job.rb
│   │   └── Services:
│   │       └── YoutubeChannelService
│   │
│   └── cleanup_job.rb
│       └── Services:
│           └── MongoCacheService
│
├── 🛠️ services/
│   ├── cache/
│   │   ├── base_cache_service.rb
│   │   ├── mongo_cache_service.rb
│   │   ├── indexable_concern.rb
│   │   └── searchable_concern.rb
│   │
│   ├── chat/
│   │   ├── chat_gpt_service.rb
│   │   └── prompt_builder.rb
│   │
│   ├── youtube/
│   │   ├── youtube_video_metadata_service.rb
│   │   ├── youtube_video_transcript_service.rb
│   │   └── youtube_channel_service.rb
│   │
│   └── user/
│       └── user_data_service.rb

🔄 Key Service Relationships:
1. MongoCacheService
   - Used by: summaries_controller, channels_controller, cleanup_job
   - Depends on: indexable_concern, searchable_concern

2. ChatGptService
   - Used by: summaries_controller, summary_generation_job
   - Depends on: prompt_builder

3. YoutubeServices
   - Used by: youtube_urls_controller, channels_controller
   - Depends on: youtube_video_transcript_service

🔍 Job Dependencies:
1. SummaryJob (app/jobs/summary_job.rb)
   - Triggered by: `SummariesController#show` when data is missing
   - Uses: Youtube::YoutubeVideoMetadataService, Youtube::YoutubeVideoTranscriptService, Ai::LlmSummaryService
   - Pushes UI updates via Turbo Streams broadcast to `"summaries:#{video_id}"` using the built-in `Turbo::StreamsChannel` (no custom channel class required)
   - Renders section partials with `locals: { summary: payload }`. Partials must use the `summary` local, not controller instance variables.

2. cleanup_job.rb
   - Scheduled task
   - Uses: MongoCacheService

Changes (2025-08-08):
- Removed `SummariesController#check_status` and route. Live updates now use websockets (Turbo Streams).
- `SummariesController#show` schedules `SummaryJob` only when data is missing/failing; otherwise it serves cached data.
- Added `SummariesChannel` and `turbo_stream_from` usage in views.

Changes (2025-08-10):
- `Youtube::YoutubeChannelService` now requests `contentDetails` when fetching channel metadata and exposes `uploads_playlist_id`.
- Channel video pagination switched from `search.list` to `playlistItems.list` using the uploads playlist for consistent `nextPageToken`/`prevPageToken` across all channels.

Notes (2025-08-12):
- No controller behavior changes for the home updates; all adjustments were view-layer only (background, demo card tabs behavior and ordering).