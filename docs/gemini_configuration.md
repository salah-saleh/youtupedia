# Gemini Configuration Guide

This document explains how to configure the Gemini API parameters in your application.

## Environment Variables

You can configure Gemini parameters using environment variables:

```bash
# Gemini API Configuration
GEMINI_API_KEY=your_gemini_api_key_here

# Gemini Model Configuration
GEMINI_MODEL=gemini-2.0-flash
GEMINI_TEMPERATURE=1.0
GEMINI_TOP_P=0.95
GEMINI_TOP_K=40
GEMINI_MAX_OUTPUT_TOKENS=20000

# Gemini Timeout Configuration
GEMINI_TIMEOUT=40
```

## Configuration Parameters

### Model Configuration
- **GEMINI_MODEL**: The Gemini model to use (default: `gemini-2.0-flash`)
- **GEMINI_TEMPERATURE**: Controls randomness in responses (0.0-2.0, default: 1.0)
- **GEMINI_TOP_P**: Nucleus sampling parameter (0.0-1.0, default: 0.95)
- **GEMINI_TOP_K**: Top-k sampling parameter (1-100, default: 40)
- **GEMINI_MAX_OUTPUT_TOKENS**: Maximum tokens in response (default: 20000)

### Performance Configuration
- **GEMINI_TIMEOUT**: Maximum time to wait for API response in seconds (default: 40)

## Programmatic Configuration

You can also configure Gemini parameters programmatically:

```ruby
# Configure Gemini client with custom parameters
config = {
  "temperature" => 0.7,
  "top_p" => 0.9,
  "max_output_tokens" => 15000
}

gemini_client = Ai::Clients::GeminiClient.new(config)

# Use in services
summary_service = Ai::LlmSummaryService.new(:gemini, config)
```

## Service-Level Configuration

Each service can have its own configuration:

```ruby
# Summary service with custom config
summary_config = {
  "temperature" => 0.5,  # More focused responses
  "max_output_tokens" => 25000
}
summary_service = Ai::LlmSummaryService.new(:gemini, summary_config)

# Takeaway expansion with different config
expansion_config = {
  "temperature" => 1.2,  # More creative responses
  "max_output_tokens" => 10000
}
expansion_service = Ai::LlmTakeawayExpanderService.new(:gemini, expansion_config)
```

## Configuration Precedence

Configuration is applied in this order (highest to lowest priority):

1. **Service-level configuration** (passed to service constructor)
2. **Client-level configuration** (passed to GeminiClient constructor)
3. **Environment variables** (GEMINI_*)
4. **Default values** (hardcoded in the base client)

## Example Use Cases

### Conservative Configuration (for summaries)
```ruby
conservative_config = {
  "temperature" => 0.3,
  "top_p" => 0.8,
  "max_output_tokens" => 30000
}
```

### Creative Configuration (for content generation)
```ruby
creative_config = {
  "temperature" => 1.5,
  "top_p" => 0.98,
  "max_output_tokens" => 15000
}
```

### Balanced Configuration (default)
```ruby
balanced_config = {
  "temperature" => 1.0,
  "top_p" => 0.95,
  "max_output_tokens" => 20000
}
```

## Monitoring and Logging

All configuration parameters are logged with each API call, making it easy to track which settings are being used:

```
[GeminiClient] Gemini API call starting | generation_config: {temperature: 0.7, top_p: 0.9, max_output_tokens: 15000}
```

## Best Practices

1. **Start with defaults**: Use the default configuration first, then adjust based on results
2. **Monitor token usage**: Lower temperature and top_p values generally result in more predictable token usage
3. **Test configurations**: Experiment with different settings on small datasets before applying to production
4. **Document changes**: Keep track of configuration changes and their impact on results
5. **Environment-specific configs**: Use different configurations for development, staging, and production
