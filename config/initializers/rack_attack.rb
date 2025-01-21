# Rack::Attack configuration for security
# Provides protection against malicious requests and rate limiting
class Rack::Attack
  ### Configure Cache ###
  Rack::Attack.cache.store = Rails.cache

  ### Blocklist Rules ###
  
  # Block WordPress scan attempts
  blocklist("block wordpress scans") do |req|
    req.path.match?(/\b(wp-includes|xmlrpc\.php|wordpress|wp-admin|wp-login)\b/)
  end

  # Block common exploit scanners
  blocklist("block exploit scanners") do |req|
    req.user_agent.to_s.downcase.match?(/\b(sqlmap|nikto|nmap|masscan|nessus|acunetix)\b/)
  end

  ### Throttle Rules ###

  # Limit all requests by IP
  throttle("req/ip", limit: 300, period: 5.minutes) do |req|
    req.ip unless req.path.start_with?("/assets/")
  end

  # Limit login attempts
  throttle("logins/ip", limit: 5, period: 20.seconds) do |req|
    if req.path == "/login" && req.post?
      req.ip
    end
  end

  # Exponential backoff for repeated blocked requests
  blocklist("fail2ban") do |req|
    Rack::Attack::Allow2Ban.filter(req.ip, maxretry: 10, findtime: 1.minutes, bantime: 1.hour) do
      req.env["rack.attack.matched"]
    end
  end

  ### Response Configuration ###
  
  self.blocklisted_response = lambda do |env|
    # Log blocked requests
    Rails.logger.info "Blocked request", 
      ip: env["action_dispatch.remote_ip"].to_s,
      path: env["PATH_INFO"],
      matched_by: env["rack.attack.matched"]

    [403, {"Content-Type" => "text/plain"}, ["Access Denied"]]
  end

  self.throttled_response = lambda do |env|
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
end 