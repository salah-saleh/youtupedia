# Puma Worker Killer Configuration
# Automatically terminates workers that exceed memory limits
#
# Memory Management Strategy:
# 1. Each worker is monitored for memory usage
# 2. Workers are killed if total memory exceeds threshold
# 3. Rolling restarts prevent memory bloat over time
#
# Dyno Size Reference:
# - Basic: 512MB  -> MAX_MEMORY_PER_PROCESS=460MB, TOTAL_MEMORY=512MB
# - Standard 1X: 1GB  -> MAX_MEMORY_PER_PROCESS=920MB, TOTAL_MEMORY=1024MB
# - Standard 2X: 2.5GB -> MAX_MEMORY_PER_PROCESS=2300MB, TOTAL_MEMORY=2560MB
# - Performance M: 2.5GB -> Same as Standard 2X
# - Performance L: 14GB -> MAX_MEMORY_PER_PROCESS=12800MB, TOTAL_MEMORY=14336MB
#
# Formula for settings:
# - TOTAL_MEMORY_MB: Dyno memory size in MB
# - MAX_MEMORY_PER_PROCESS: (TOTAL_MEMORY_MB * 0.9) to leave room for system
# - Rolling restart: Every 12 hours to prevent memory bloat
# - Check frequency: Every 60 seconds (adjust based on traffic)
if defined?(PumaWorkerKiller) && Rails.env.production?
  # Only run in master process to avoid duplicate threads
  # Note: You may still see thread warnings in development, but they won't affect production
  if Process.const_defined?(:CLOCK_MONOTONIC) && Process.pid == 2 # Master PID is 2 on Heroku
    # Total RAM available to the dyno
    # Default: 512MB (Basic dyno)
    # Adjust based on dyno size: set to actual dyno memory in MB
    PumaWorkerKiller.ram = ENV.fetch("TOTAL_MEMORY_MB", 512).to_i

    # How often to check memory usage
    # Default: 60 seconds
    # - Lower for faster response to memory issues
    # - Higher for less overhead
    # Recommendation:
    # - High traffic: 30 seconds
    # - Medium traffic: 60 seconds
    # - Low traffic: 120 seconds
    PumaWorkerKiller.frequency = 60

    # Percentage of RAM at which to start killing workers
    # Default: 0.98 (98%)
    # - Lower means more aggressive memory management
    # - Higher means more risk of hitting dyno limits
    # Recommendation:
    # - Basic/Standard-1X: 0.98
    # - Standard-2X/Performance: 0.95
    PumaWorkerKiller.percent_usage = 0.98

    # How often to restart all workers
    # Default: 12 hours
    # - Lower for more aggressive memory cleanup
    # - Higher for less disruption
    # Recommendation:
    # - High memory usage: 6 hours
    # - Normal usage: 12 hours
    # - Low memory usage: 24 hours
    PumaWorkerKiller.rolling_restart_frequency = 12 * 3600 # 12 hours

    # Enable detailed logging of worker kills
    PumaWorkerKiller.reaper_status_logs = true

    # Log when PumaWorkerKiller starts
    Rails.logger.info("PumaWorkerKiller configured: " + {
      ram_limit: PumaWorkerKiller.ram,
      percent_usage: PumaWorkerKiller.percent_usage,
      frequency: PumaWorkerKiller.frequency,
      rolling_restart: PumaWorkerKiller.rolling_restart_frequency
    }.inspect)

    # Handle graceful shutdowns
    at_exit do
      # Stop PumaWorkerKiller threads before exit
      if Thread.list.size > 1
        Thread.list.each do |thread|
          next if thread == Thread.current
          thread.kill if thread.backtrace&.first&.include?('puma_worker_killer')
        end
      end
    end

    # Configure reap cycle before starting
    PumaWorkerKiller.reap_cycle_in_seconds = 30 # Default is 60

    # Start PumaWorkerKiller
    PumaWorkerKiller.start
  end
end 