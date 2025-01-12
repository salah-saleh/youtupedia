# YouTube Video Summarizer

An AI-powered application that generates concise summaries of YouTube videos using OpenAI's GPT model. Built with Ruby on Rails and modern web technologies.

For more details about the product structure, see the [product.md](product.md) file.

## Features

- 🎥 YouTube video summarization
- 🤖 AI-powered content analysis
- 🔍 Full-text search across summaries
- 📱 Mobile-responsive design
- 🔐 User authentication
- 💾 Efficient caching system

## Tech Stack

- **Framework**: Ruby on Rails 8
- **Databases**:
  - PostgreSQL (user data)
  - MongoDB (caching & search)
- **Frontend**:
  - Tailwind CSS
  - Hotwire (Turbo & Stimulus)
- **APIs**:
  - YouTube Data API
  - OpenAI GPT API
- **Deployment**:
  - Docker
  - Heroku

## Prerequisites

- Ruby 3.x
- Docker & Docker Compose
- PostgreSQL
- MongoDB
- YouTube API Key
- OpenAI API Key

## Setup

1. **Clone the repository**   ```bash
   git clone [repository-url]
   cd [repository-name]   ```

2. **Environment Variables**   ```bash
   cp .env.example .env
   # Edit .env with your API keys and configuration   ```

3. **Docker Setup**   ```bash
   docker-compose build
   docker-compose up   ```

4. **Database Setup**   ```bash
   docker-compose exec web rails db:create
   docker-compose exec web rails db:migrate   ```

5. **Start the Application**   ```bash
   docker-compose up   ```

   Visit `http://localhost:3000`

## Development

### Key Directories

- `app/controllers/` - Application controllers
- `app/models/` - Data models
- `app/services/` - Business logic services
- `app/views/` - View templates
- `spec/` - Test files

### Running Tests

```bash
docker-compose exec web rspec
```

### Code Style

- Follow Rails conventions
- Use Tailwind CSS for styling
- Keep components modular
- Document code changes

## API Integration

### YouTube API
- Required for fetching video metadata and transcripts
- Set `YOUTUBE_API_KEY` in `.env`

### OpenAI API
- Powers the summarization feature
- Set `OPENAI_API_KEY` in `.env`

## Caching Strategy

- MongoDB for caching video metadata and transcripts
- Indexed search functionality
- Efficient data retrieval system

## Cache Setup

The application uses Memcached for:
- Job deduplication
- Request rate limiting
- Fragment caching
- Session storage

### Local Development

#### Using Docker (Recommended)
Memcached is automatically configured when using Docker:
```bash
docker-compose up
```

#### Manual Setup
1. Install Memcached:
```bash
# macOS
brew install memcached
brew services start memcached

# Ubuntu/Debian
sudo apt-get install memcached
sudo systemctl start memcached
```

2. Verify installation:
```bash
telnet localhost 11211
```

### Production Setup

The app expects these environment variables:
- `MEMCACHIER_SERVERS`: Comma-separated list of Memcached servers
- `MEMCACHIER_USERNAME`: (Optional) Authentication username
- `MEMCACHIER_PASSWORD`: (Optional) Authentication password

#### Heroku Setup
```bash
heroku addons:create memcachier:dev
```

### Cache Configuration

Development:
```ruby
# config/environments/development.rb
config.cache_store = :mem_cache_store,
  "localhost:11211",
  {
    namespace: "youtupedia_dev",
    compress: true,
    failover: true,
    socket_timeout: 3.0,
    pool_size: 5,
    expires_in: 1.day
  }
```

Production:
```ruby
# config/environments/production.rb
config.cache_store = :mem_cache_store,
  ENV["MEMCACHIER_SERVERS"].split(","),
  {
    username: ENV["MEMCACHIER_USERNAME"],
    password: ENV["MEMCACHIER_PASSWORD"],
    failover: true,
    socket_timeout: 3.0,
    socket_failure_delay: 0.2,
    down_retry_delay: 60,
    pool_size: 5
  }
```

## Contributing

1. Fork the repository
2. Create your feature branch
3. Commit your changes
4. Push to the branch
5. Create a Pull Request

## License

[Your License Type] - See LICENSE.md for details

## Support

For support, please [create an issue](repository-issues-url) or contact the maintainers.
