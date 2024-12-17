📁 app/
├── 🎮 controllers/
│   ├── application_controller.rb
│   │   └── Concerns:
│   │       ├── authentication.rb
│   │       └── error_handling.rb
│   │
│   ├── summaries_controller.rb
│   │   └── Services:
│   │       ├── ChatGptService
│   │       ├── YoutubeFetchService
│   │       └── MongoCacheService
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
1. summary_generation_job.rb
   - Triggered by: summaries_controller
   - Uses: ChatGptService, MongoCacheService

2. transcript_fetch_job.rb
   - Triggered by: youtube_urls_controller
   - Uses: YoutubeVideoTranscriptService

3. channel_sync_job.rb
   - Triggered by: channels_controller
   - Uses: YoutubeChannelService

4. cleanup_job.rb
   - Scheduled task
   - Uses: MongoCacheService

💡 Recommendations:
1. Consider extracting common controller logic into concerns
2. Look for opportunities to share helper methods across controllers
3. Consider implementing service result objects for better error handling
4. Review job retry strategies and error handling
5. Consider implementing service interfaces for better abstraction
6. Review cache invalidation strategies
7. Consider implementing service metrics/monitoring