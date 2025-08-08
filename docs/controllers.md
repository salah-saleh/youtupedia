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
│   │
│   ├── channels_controller.rb
│   │   └── Services:
│   │       ├── YoutubeChannelService
│   │       └── MongoCacheService
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

2. cleanup_job.rb
   - Scheduled task
   - Uses: MongoCacheService

Changes (2025-08-08):
- Removed `SummariesController#check_status` and route. Live updates now use websockets (Turbo Streams).
- `SummariesController#show` schedules `SummaryJob` only when data is missing/failing; otherwise it serves cached data.
- Added `SummariesChannel` and `turbo_stream_from` usage in views.