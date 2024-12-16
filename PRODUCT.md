# Application Structure

## Core Application Components

### Controllers (`app/controllers/`)
- `application_controller.rb` - Base controller with shared functionality
- `summaries_controller.rb` - Handles video summary creation and display
- `youtube_urls_controller.rb` - Processes YouTube URL inputs
- `search_controller.rb` - Manages search functionality
- `channels_controller.rb` - Handles YouTube channel operations

### Models (`app/models/`)
- `user.rb` - User authentication and relationships
- `session.rb` - User session management
- `current.rb` - Request-specific context management

### Services (`app/services/`)
#### Cache Services (`app/services/cache/`)
- `base_cache_service.rb` - Abstract cache interface
- `mongo_cache_service.rb` - MongoDB implementation
- `indexable_concern.rb` - MongoDB indexing functionality
- `searchable_concern.rb` - Text search capabilities

#### Chat Services (`app/services/chat/`)
- `chat_gpt_service.rb` - OpenAI integration for summaries
- `prompt_builder.rb` - Constructs GPT prompts

#### YouTube Services (`app/services/youtube/`)
- `youtube_video_metadata_service.rb` - Fetches video metadata
- `youtube_video_transcript_service.rb` - Handles video transcripts
- `youtube_channel_service.rb` - Channel data operations

#### User Services (`app/services/user/`)
- `user_data_service.rb` - User-specific data management

### Views (`app/views/`)
#### Layouts
- `application.html.erb` - Main application layout
- `dashboard.html.erb` - Dashboard layout template

#### Summaries
- `index.html.erb` - List of user's summaries
- `show.html.erb` - Individual summary view
- `_summary_detail.html.erb` - Summary component

#### Channels
- `index.html.erb` - Channel listing
- `show.html.erb` - Channel details

#### Shared Components (`app/views/shared/`)
- `_header.html.erb` - Navigation header
- `_footer.html.erb` - Footer component
- `_loading.html.erb` - Loading states

## Configuration

### Database
- `config/database.yml` - PostgreSQL configuration
- `config/mongoid.yml` - MongoDB configuration

### Environment
- `.env` - Environment variables
- `config/application.rb` - Rails application config
- `config/routes.rb` - Application routing

## Assets and Styling
- `app/assets/stylesheets/application.tailwind.css` - Tailwind CSS entry
- `tailwind.config.js` - Tailwind configuration

## Testing
- `spec/` - RSpec test files
- `spec/services/` - Service tests
- `spec/controllers/` - Controller tests

## Docker
- `Dockerfile` - Container configuration
- `docker-compose.yml` - Service orchestration

## Key Relationships

### Data Flow
1. User submits YouTube URL
2. `youtube_urls_controller.rb` processes URL
3. `youtube_video_metadata_service.rb` fetches metadata
4. `youtube_video_transcript_service.rb` gets transcript
5. `chat_gpt_service.rb` generates summary
6. Results cached via `mongo_cache_service.rb`
7. `summaries_controller.rb` displays results

### Caching Strategy
- Metadata cached in MongoDB
- Transcripts stored in separate collection
- Search indexes maintained via `indexable_concern.rb`
- Full-text search via `searchable_concern.rb`

### Authentication Flow
1. `application_controller.rb` checks authentication
2. `session.rb` manages user sessions
3. `current.rb` maintains request context
4. User data accessed via `user_data_service.rb`

## Development Workflow
1. Local development via Docker Compose
2. Environment variables from `.env`
3. MongoDB for caching and search
4. PostgreSQL for user data
5. Tailwind CSS for styling
6. Heroku for deployment

# Additional Components

## JavaScript (`app/javascript/`)
### Controllers (`app/javascript/controllers/`)
- `search_controller.js` - Handles search input and results
- `summary_controller.js` - Manages summary view interactions
- `video_controller.js` - YouTube video player integration
- `loading_controller.js` - Loading state management

### Utils (`app/javascript/utils/`)
- `api.js` - API request helpers
- `formatters.js` - Date and text formatting utilities
- `validators.js` - Input validation helpers

## Background Jobs (`app/jobs/`)
- `application_job.rb` - Base job class
- `summary_generation_job.rb` - Async summary creation
- `transcript_fetch_job.rb` - Async transcript fetching
- `channel_sync_job.rb` - YouTube channel synchronization
- `cleanup_job.rb` - Cache and temporary data cleanup

## Libraries (`lib/`)

### Logging System (`lib/logging/`)
- `logging.rb` - Core logging functionality
  - Global logging methods
  - Class and instance-level logging
  - Context and truncation support
- `formatter.rb` - Log formatting
  - Colored severity levels
  - Timestamp formatting
  - Component-based message formatting
- `helper.rb` - Logging utilities
  - Data truncation
  - Array and hash formatting
  - Object inspection

### Python Integration (`lib/python/`)
- `youtube_transcript.py` - YouTube transcript fetching
  - Proxy support for region restrictions
  - Retry mechanism with exponential backoff
  - JSON-formatted responses

### Rake Tasks (`lib/tasks/`)
- `cache_migration.rake` - Database migration tasks
  - File cache to MongoDB migration
  - Namespace-based migration support
  - Error handling and reporting
- `.keep` - Git directory placeholder

## Key Relationships

### Logging Integration
1. `Logging` module included globally in `Object`
2. Services use logging methods for debugging and monitoring
3. Formatter handles structured log output
4. Helper provides data truncation and formatting

### Python Integration Flow
1. Ruby services call Python script for transcripts
2. Proxy handling for region-restricted content
3. Retry mechanism for reliability
4. JSON-based communication between Ruby and Python

### Task Usage
1. Cache migration for database transitions
2. Supports multiple service namespaces
3. Handles both metadata and transcript data
