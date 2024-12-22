class TestController < ApplicationController
  def debug
    log_debug "Test debug message"
    log_info "Test info message"
    log_warn "Test warn message"
    log_error "Test error message"
    render plain: "Logged test messages"
  end
end
