# Check if system time is properly synchronized
# This is important for:
# - Proper logging timestamps
# - Authentication tokens
# - Rate limiting
# - Background job scheduling

if Rails.env.production?
  begin
    # Get current time from NTP server
    require "net/ntp"
    ntp_time = Net::NTP.get("pool.ntp.org").time
    system_time = Time.now
    time_diff = (ntp_time - system_time).abs

    if time_diff > 300 # 5 minutes
      Rails.logger.warn("System time is out of sync: " + {
        system_time: system_time,
        ntp_time: ntp_time,
        difference_seconds: time_diff.round(2)
      }.inspect)
    end
  rescue => e
    Rails.logger.warn("Failed to check time synchronization: #{e.message}")
  end
end 