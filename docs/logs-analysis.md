# Log Analysis Tools

This application includes tools for analyzing application logs in both real-time and from existing log files.

## Basic Usage

```bash
# Watch logs in real-time with analysis
rails logs:watch

# Analyze existing logs
rails logs:analyze

# Extract logs for a specific request ID
rails logs:request REQUEST_ID=abc-123

# Debug mode for detailed output
DEBUG=1 rails logs:watch
```

## Configuration Options

```bash
# Specify a different log file
LOG_FILE=custom.log rails logs:analyze
LOG_FILE=custom.log rails logs:request REQUEST_ID=abc-123

# Enable debug output for detailed processing information
DEBUG=1 rails logs:watch
DEBUG=1 rails logs:analyze
```

## Log Format

The analyzer supports our custom log format:
```
TIMESTAMP | SEVERITY | rid=REQUEST_ID | [sid=SESSION_ID] [uid=USER_ID] [ip=IP_ADDRESS] [Controller] [action] Message | {context}
```

Example:
```
2024-12-25 14:32:14.789 | DEBUG | rid=c841852d-aa2f-40b9-843b-2e2904bcc9f1 | [sid=72] [uid=1] [ip=127.0.0.1] [ChannelsController] [channels] Request started | {request_id: c841852d..., session_id: 72, user_id: 1, controller: channels, action: index}
```

## Analysis Features

### Real-time Analysis (`logs:watch`)
- Total requests and pending requests count
- Error tracking with recent errors display
- Average response times with min/max ranges
- Top controllers with request counts and timing stats
- Recent requests with status codes and durations
- Active pending requests with elapsed time

### Log File Analysis (`logs:analyze`)
- Same metrics as real-time analysis
- Full log file processing
- Historical request patterns
- Performance trends

### Request Tracking (`logs:request`)
- Extract all logs for a specific request ID
- Grouped by severity level (DEBUG, INFO, WARN, ERROR, FATAL)
- Summary statistics showing:
  - Total log entries
  - Breakdown by severity with percentages
- Chronological display within severity groups
- Clean formatting with timestamps and indented messages

## Example Outputs

### Request Analysis
```bash
$ rails logs:request REQUEST_ID=c841852d-aa2f-40b9-843b-2e2904bcc9f1

Found 45 log entries

DEBUG: 35 lines (77.8%)
INFO: 10 lines (22.2%)

DEBUG Logs:
============
2024-12-25 14:32:14.789
  [ChannelsController] [channels] Loading channel data...

INFO Logs:
============
2024-12-25 14:32:14.799
  [ChannelsController] [channels] Request completed | {duration_ms: 20.4, status: 200}
```

### Real-time Analysis
```bash
$ rails logs:watch

Log Analysis Statistics
======================
Total Requests: 8
Pending Requests: 0
Error Count: 0
Average Response Time: 38.14ms
Response Time Range: 19.79ms - 71.37ms

Top Controllers:
  SummariesController#show: 3 requests (avg: 44.34ms, range: 27.14ms - 59.97ms)
  ChannelsController#index: 3 requests (avg: 39.89ms, range: 20.4ms - 71.37ms)
  SummariesController#index: 2 requests (avg: 26.22ms, range: 19.79ms - 32.64ms)

Recent Requests:
  GET /channels [ChannelsController#index] - 200 (71.37ms)
  GET /summaries [SummariesController#index] - 200 (32.64ms)
  GET /summaries/vOlAniUTlCY [SummariesController#show] - 200 (59.97ms)
```

## Implementation Details

The log analysis tools are implemented in `lib/tasks/logs.rake` and work in conjunction with:
- `lib/logging/formatter.rb` - Custom log formatting
- `lib/custom_logger.rb` - Application logger configuration
- `config/environments/development.rb` - Logger setup

The system uses Rails' tagged logging capabilities and includes:
- Request ID tracking
- Session ID context
- User ID context
- IP address tracking
- Controller/action context
- Performance metrics

## Future Enhancements

Planned improvements:
- MongoDB timing analysis
- ActiveRecord query statistics
- View rendering time tracking
- Garbage collection metrics
- Export capabilities (CSV, JSON)
- Advanced filtering options
- Custom metric tracking