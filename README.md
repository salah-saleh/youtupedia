# YouTube Video Summarizer

An AI-powered application that generates concise summaries of YouTube videos using OpenAI's GPT model. Built with Ruby on Rails and modern web technologies.

## Features

- 🎥 YouTube video summarization
- 🤖 AI-powered content analysis
- 🔊 Audio summaries using Gemini TTS with Algenib voice
- 🔍 Full-text search across summaries
- 📱 Mobile-responsive design

## Tech Stack

- **Framework**: Ruby on Rails 8
- **Databases**:
  - PostgreSQL (user data)
  - MongoDB (summaries)
- **Frontend**:
  - Tailwind CSS
  - Hotwire (Turbo & Stimulus)
- **APIs**:
  - YouTube Data API
  - OpenAI GPT API
  - Gemini
- **Deployment**:
  - Docker
  - GCP

## Prerequisites

- Ruby 3.x
- Docker & Docker Compose
- PostgreSQL
- MongoDB

## Setup

This application requires both Ruby and Python dependencies. To set up your development environment:

1. Make sure you have Python 3.x installed
2. Run `bin/setup` to install all dependencies and set up the environment
3. Run `bin/dev` to start the development server

If you get Python-related errors, try running `bin/setup` again to ensure all dependencies are properly installed.

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

