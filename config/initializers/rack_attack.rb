# Rack::Attack configuration for security
# Provides protection against malicious requests and rate limiting

# Enable Rack::Attack first
Rack::Attack.enabled = true

# Rack::Attack configuration
class Rack::Attack
  ### Configure Cache ###
  
  # Use Memcached for rate limiting
  if defined?(Rails.cache) && Rails.cache.is_a?(ActiveSupport::Cache::MemCacheStore)
    Rack::Attack.cache.store = Rails.cache
  else
    # Fallback to memory store if memcached is not available
    memory_store = ActiveSupport::Cache::MemoryStore.new(size: 128.megabytes)
    Rack::Attack.cache.store = memory_store
  end

  # Add debug logging for all requests
  ActiveSupport::Notifications.subscribe("rack.attack") do |name, start, finish, request_id, payload|
    if payload[:request]
      Rails.logger.info("[Rack::Attack] " + {
        path: payload[:request].path,
        ip: payload[:request].ip,
        matched: payload[:matched],
        match_type: payload[:match_type],
        match_data: payload[:match_data],
        cache_key: "#{name}:#{payload[:discriminator]}"
      }.inspect)
    end
  end

  ### Blocklist Rules ###
  
  # Block requests to invalid hostnames
  blocklist("block invalid hosts") do |request|
    begin
      # List of valid hostnames for our application
      valid_hosts = [
        "youtupedia.ai",
        "www.youtupedia.ai",
        "youtupedia-290655871106.europe-west1.run.app",
        "localhost",
        "0.0.0.0"
      ]

      # Add development hosts
      if !Rails.env.production?
        valid_hosts += [
          "localhost",
          "127.0.0.1",
          "::1",
          "0.0.0.0"
        ]
      end

      host = request.host.to_s.downcase
      is_blocked = !valid_hosts.include?(host)

      # Log the decision for debugging
      if is_blocked
        Rails.logger.info("Blocking invalid host: " + {
          host: host,
          valid_hosts: valid_hosts,
          request_id: request.env["action_dispatch.request_id"]
        }.inspect)
      end

      is_blocked
    rescue => e
      # Log any errors in the hostname checking
      Rails.logger.error("Error in hostname check: #{e.message}")
      false  # Don't block if there's an error
    end
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

  # Short-term rate limit (per second)
  throttle("req/ip/sec", limit: 5, period: 1.second) do |request|
    request.ip unless request.path.start_with?('/assets/', '/packs/')
  end

  # Medium-term rate limit (per minute)
  throttle("req/ip/min", limit: 60, period: 1.minute) do |request|
    request.ip unless request.path.start_with?('/assets/', '/packs/')
  end

  # Long-term rate limit (per 5 minutes)
  throttle("req/ip/5min", limit: 100, period: 5.minutes) do |request|
    request.ip unless request.path.start_with?('/assets/', '/packs/')
  end

  # Login rate limits
  throttle("logins/ip", limit: 5, period: 20.seconds) do |request|
    request.ip if request.path == "/session" && request.post?
  end

  # API-specific rate limits
  throttle("api/ip", limit: 60, period: 1.minute) do |request|
    request.ip if request.path.start_with?('/api/')
  end

  # Search rate limits
  throttle("search/ip", limit: 30, period: 1.minute) do |request|
    request.ip if request.path.start_with?('/search')
  end

  # GPT rate limits
  throttle("gpt/ip", limit: 10, period: 1.minute) do |request|
    request.ip if request.path.include?('/ask_gpt')
  end

  # Exponential backoff for repeated blocked requests
  blocklist("fail2ban") do |request|
    Rack::Attack::Allow2Ban.filter(request.ip, maxretry: 10, findtime: 1.minutes, bantime: 1.hour) do
      request.env["rack.attack.matched"]
    end
  end

  ### Response Configuration ###
  
  # Configure blocked request response
  blocklisted_responder = ->(req) do
    # Get request details safely from env
    env = req.env
    
    # Log blocked requests with more detail
    Rails.logger.info("Blocked malicious request: " + {
      ip: env["REMOTE_ADDR"],
      path: env["PATH_INFO"],
      host: env["HTTP_HOST"],
      matched_by: env["rack.attack.matched"],
      user_agent: env["HTTP_USER_AGENT"]
    }.inspect)

    [403, {"Content-Type" => "text/plain"}, ["Access Denied"]]
  end

  # Configure rate limit exceeded response
  self.throttled_response = lambda do |env|
    [ 429,
      {'Content-Type' => 'text/plain'},
      ["Rate Limit Exceeded. Try again in #{env['rack.attack.match_data'][:period]} seconds\n"]
    ]
  end

  # Set the responders
  self.blocklisted_responder = blocklisted_responder
end

if Rails.env.development?
  ActiveSupport::Notifications.subscribe("rack.attack") do |name, start, finish, request_id, payload|
    req = payload[:request]
    
    if payload[:matched]
      puts "[Rack::Attack][Blocked] " + {
        path: req.path,
        host: req.host,
        ip: req.ip,
        matched_by: payload[:matched]
      }.inspect
    end
  end
end 