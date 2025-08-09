# This configuration file will be evaluated by Puma. The top-level methods that
# are invoked here are part of Puma's configuration DSL. For more information
# about methods provided by the DSL, see https://puma.io/puma/Puma/DSL.html.
#
# Puma starts a configurable number of processes (workers) and each process
# serves each request in a thread from an internal thread pool.
#
# You can control the number of workers using ENV["WEB_CONCURRENCY"]. You
# should only set this value when you want to run 2 or more workers. The
# default is already 1.
#
# The ideal number of threads per worker depends both on how much time the
# application spends waiting for IO operations and on how much you wish to
# prioritize throughput over latency.
#
# As a rule of thumb, increasing the number of threads will increase how much
# traffic a given process can handle (throughput), but due to CRuby's
# Global VM Lock (GVL) it has diminishing returns and will degrade the
# response time (latency) of the application.
#
# The default is set to 3 threads as it's deemed a decent compromise between
# throughput and latency for the average Rails application.
#
# Any libraries that use a connection pool or another resource pool should
# be configured to provide at least as many connections as the number of
# threads. This includes Active Record's `pool` parameter in `database.yml`.
# Run a single worker so Action Cable (async adapter) broadcasts
# reach the same process that serves the websocket subscription. Multiple
# workers require a pub/sub backend (e.g., Redis) for cross-process delivery.
workers Integer(ENV.fetch("WEB_CONCURRENCY", 0))


threads_count = Integer(ENV.fetch("RAILS_MAX_THREADS", 3))
threads threads_count, threads_count

# Specifies the `port` that Puma will listen on to receive requests; default is 3000.
port ENV.fetch("PORT", 3000)

# Specifies the `environment` that Puma will run in.
environment ENV.fetch("RAILS_ENV", "development")

# Run the Solid Queue supervisor inside of Puma for single-server deployments
plugin :solid_queue if ENV["SOLID_QUEUE_IN_PUMA"]

# Specify the PID file. Defaults to tmp/pids/server.pid in development.
# In other environments, only set the PID file if requested.
pidfile ENV["PIDFILE"] if ENV["PIDFILE"]

# Allow puma to be restarted by `rails restart` command.
plugin :tmp_restart

# Production-specific settings
if ENV["RAILS_ENV"] == "production"
  # Preload the application for better performance
  preload_app!

  # Before forking the application, disconnect from connected services
  if Integer(ENV.fetch("WEB_CONCURRENCY", 0)) > 0
    before_fork do
      ActiveRecord::Base.connection_pool.disconnect! if defined?(ActiveRecord)

      # Stop PumaWorkerKiller threads before forking
      if defined?(PumaWorkerKiller)
        Thread.list.each do |thread|
          next if thread == Thread.current
          thread.kill if thread.backtrace&.first&.include?('puma_worker_killer')
        end
      end
    end
  end

  # After forking, reconnect to services
  if Integer(ENV.fetch("WEB_CONCURRENCY", 0)) > 0
    on_worker_boot do
      ActiveRecord::Base.establish_connection if defined?(ActiveRecord)
    end
  end
end

# Increase worker timeout to prevent frequent restarts
worker_timeout 3600 if ENV.fetch("RAILS_ENV", "development") == "development"

# Note: The following thread warnings are expected and normal:
# - PumaWorkerKiller memory monitoring thread
# - PumaWorkerKiller rolling restart thread
# These threads are required for proper memory management.

# Lower the timeout for worker shutdown but give enough time for threads to clean up
worker_shutdown_timeout 25 # Give workers 25 seconds to finish, less than Heroku's 30s timeout

# Only register worker shutdown hook when running in cluster mode
if Integer(ENV.fetch("WEB_CONCURRENCY", 0)) > 0
  on_worker_shutdown do |index|
    # Give PumaWorkerKiller threads time to finish their current cycle
    sleep 1 if defined?(PumaWorkerKiller)
  end
end
