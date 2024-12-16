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
- Node.js 16+
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
