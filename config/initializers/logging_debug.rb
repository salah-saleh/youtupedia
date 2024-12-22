Rails.logger.debug "Rails logger initialized with formatter: #{Rails.logger.formatter.class}"
Rails.logger.debug "Log level: #{Rails.logger.level}"

# Test each log level
Rails.logger.debug "Debug test message"
Rails.logger.info "Info test message"
Rails.logger.warn "Warn test message"
Rails.logger.error "Error test message"
