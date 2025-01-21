# Rack::Attack configuration for security
# Provides protection against malicious requests and rate limiting

# Configure Redis cache for rate limiting
class Rack::Attack
  ### Configure Cache ###
  # Use Rails cache (Memcached) for rate limiting
  Rack::Attack.cache.store = ActiveSupport::Cache::MemoryStore.new

  ### Blocklist Rules ###
  
  # Block requests to invalid hostnames
  blocklist("block invalid hosts") do |request|
    valid_hosts = ["youtupedia.ai", "www.youtupedia.ai"]
    !valid_hosts.include?(request.host.downcase)
  end

  # Block PHP and WordPress scan attempts
  blocklist("block php scans") do |request|
    path = request.path.to_s.downcase
    
    # Block any PHP file access attempts
    path.end_with?('.php', '.php7') ||
      # Block WordPress-specific paths
      path.include?('wp-content') ||
      path.include?('wp-includes') ||
      path.include?('wordpress') ||
      path.include?('wp-admin') ||
      path.include?('wp-login') ||
      path.include?('xmlrpc.php')
  end

  # Block common exploit scanners
  blocklist("block exploit scanners") do |request|
    # Match scanner user agents more precisely
    user_agent = request.user_agent.to_s.downcase
    user_agent.include?("sqlmap") ||
      user_agent.include?("nikto") ||
      user_agent.include?("nmap") ||
      user_agent.include?("masscan") ||
      user_agent.include?("nessus") ||
      user_agent.include?("acunetix")
  end

  ### Throttle Rules ###

  # Limit all requests by IP
  throttle("req/ip", limit: 300, period: 5.minutes) do |request|
    request.ip unless request.path.start_with?("/assets/")
  end

  # Limit login attempts
  throttle("logins/ip", limit: 5, period: 20.seconds) do |request|
    if request.path == "/login" && request.post?
      request.ip
    end
  end

  # Exponential backoff for repeated blocked requests
  blocklist("fail2ban") do |request|
    Rack::Attack::Allow2Ban.filter(request.ip, maxretry: 10, findtime: 1.minutes, bantime: 1.hour) do
      request.env["rack.attack.matched"]
    end
  end

  ### Response Configuration ###
  
  # Configure blocked request response
  blocklisted_responder = ->(env) do
    # Log blocked requests with more detail
    Rails.logger.info("Blocked malicious request: " + {
      ip: env["action_dispatch.remote_ip"].to_s,
      path: env["PATH_INFO"],
      matched_by: env["rack.attack.matched"],
      user_agent: env["HTTP_USER_AGENT"],
      request_id: env["action_dispatch.request_id"]
    }.inspect)

    [403, {"Content-Type" => "text/plain"}, ["Access Denied"]]
  end

  # Configure rate limit exceeded response
  throttled_responder = ->(env) do
    now = Time.now
    match_data = env["rack.attack.match_data"]
    retry_after = (match_data[:period] - (now.to_i % match_data[:period])).to_s

    [
      429,
      {
        "Content-Type" => "text/plain",
        "Retry-After" => retry_after
      },
      ["Rate Limit Exceeded. Retry in #{retry_after} seconds"]
    ]
  end

  # Set the responders
  self.blocklisted_responder = blocklisted_responder
  self.throttled_responder = throttled_responder
end 