# Log Analysis Tools

This application includes tools for analyzing both development and production logs.

## Usage

### Development Logs

```bash
# Watch logs in real-time with pretty formatting
DEBUG=1 rails logs:watch

# Watch logs with JSON format
PRETTY_LOGS=0 rails logs:watch

# Analyze existing logs
rails logs:analyze

# Analyze specific log file
LOG_FILE=custom.log rails logs:analyze
```

### Production (Heroku) Logs

```bash
# Watch Heroku logs (raw)
heroku logs --tail

# Watch Heroku logs with formatting
HEROKU=1 rails logs:watch

# Analyze Heroku logs
HEROKU=1 rails logs:analyze

# Analyze more lines
HEROKU=1 LINES=2000 rails logs:analyze

# Filter Heroku logs
heroku logs --dyno web.1            # Filter by dyno
heroku logs --source app            # Filter by source
heroku logs --since "2024-01-01"    # Filter by date
heroku logs -n 1000 --timestamps    # Show timestamps
```

### Log Filtering and Analysis

```bash
# Save logs for analysis
heroku logs -n 1000 > production.log
rails logs:analyze LOG_FILE=production.log

# Filter logs using jq
cat production.log | jq 'select(.user_id == "123")'        # Find user requests
cat production.log | jq 'select(.duration_ms > 1000)'      # Find slow requests
cat production.log | jq 'select(.request_id == "abc123")'  # Track specific request
cat production.log | jq 'select(.level == "ERROR")'        # Show only errors
```

### Log Drains (Production)

```bash
# Add log drain service
heroku drains:add syslog+tls://logs.papertrailapp.com:12345  # Papertrail
heroku drains:add syslog+tls://loggly.com:12345              # Loggly
heroku drains:add https://logdna.com/webhook                 # LogDNA

# List current drains
heroku drains

# Remove a drain
heroku drains:remove DRAIN_URL
```

## Log Formats Supported

The analyzer supports:
- JSON-formatted logs (from CustomLogger)
- Standard Rails logs
- Heroku logs
- Log drain formats

## Analysis Features

- Request statistics
  - Total requests
  - Completed/pending requests
  - Status code breakdown
  - Average response times
- Error tracking
  - Error counts
  - Error details with stack traces
- Path-based analytics
  - Most requested paths
  - Slowest paths
  - Error rates per path
- Performance monitoring
  - Response time trends
  - Slow request identification
  - Resource usage patterns

## Configuration

### Development
- Set `PRETTY_LOGS=1` for colored output
- Adjust worker timeout in `config/puma.rb`
- Configure log level in environment files
- Customize log format in `config/environments/development.rb`

### Production
- Uses JSON format by default
- Supports multiple log drains
- Configurable through environment variables:
  - `LOG_LEVEL`: Set logging detail level
  - `PRETTY_LOGS`: Enable/disable formatting
  - `LOG_DRAIN_URL`: Configure external logging service

### Advanced Usage

```bash
# Watch logs with custom format
PRETTY_LOGS=1 LOG_LEVEL=debug rails logs:watch

# Analyze with extended statistics
DETAILED=1 rails logs:analyze

# Export analysis to file
rails logs:analyze > analysis.txt

# Monitor specific paths
cat production.log | jq 'select(.path | contains("/api/"))'



Add more analysis metrics?
Show how to export to different formats?
Add real-time monitoring capabilities?

Add more Heroku-specific logging features?
Show how to set up log drains?

Add data export capabilities?
Add filtering options?

Add more log format support?
Add worker monitoring features?
Improve the error handling?

Add more analysis metrics?
Add data export capabilities?
Add filtering options?

Add more detailed request tracking?
Add path-based statistics?
Show request timing trends?