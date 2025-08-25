namespace :jobs do
  desc "Clear stuck job cache keys"
  task :clear_cache, [:job_class, :args] => :environment do |task, args|
    job_class = args[:job_class]&.constantize
    job_args = args[:args]&.split(',') || []
    
    if job_class.nil?
      puts "Usage: rails jobs:clear_cache[JobClassName,arg1,arg2,...]"
      puts "Example: rails jobs:clear_cache[SummaryJob,nudFRCeJfsA]"
      exit 1
    end
    
    unless job_class.respond_to?(:clear_job_cache)
      puts "Error: #{job_class} does not include JobSchedulable"
      exit 1
    end
    
    deleted = job_class.clear_job_cache(*job_args)
    if deleted
      puts "Successfully cleared cache key for #{job_class} with args: #{job_args.inspect}"
    else
      puts "No cache key found for #{job_class} with args: #{job_args.inspect}"
    end
  end

  desc "List all job cache keys (requires Redis/Memcached inspection)"
  task :list_cache_keys => :environment do
    # This will depend on your cache backend
    if Rails.cache.class.name.include?("Redis")
      keys = Rails.cache.redis.keys("*job*")
      puts "Job-related cache keys:"
      keys.each { |key| puts "  #{key}" }
    elsif Rails.cache.class.name.include?("Dalli")
      puts "Memcached doesn't support key listing. Use specific key checks instead."
    else
      puts "Cache backend #{Rails.cache.class} doesn't support key listing"
    end
  end

  desc "Clear specific job cache key manually"
  task :clear_summary_job, [:video_id] => :environment do |task, args|
    video_id = args[:video_id]
    if video_id.nil?
      puts "Usage: rails jobs:clear_summary_job[video_id]"
      puts "Example: rails jobs:clear_summary_job[nudFRCeJfsA]"
      exit 1
    end
    
    deleted = SummaryJob.clear_job_cache(video_id)
    if deleted
      puts "Successfully cleared SummaryJob cache for video: #{video_id}"
    else
      puts "No cache key found for SummaryJob with video: #{video_id}"
    end
  end
end
