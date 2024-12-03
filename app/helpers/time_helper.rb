module TimeHelper
  def format_duration(seconds)
    return "0s" if seconds.nil?

    # Convert to integer seconds
    seconds = seconds.to_f.round

    hours = seconds / 3600
    minutes = (seconds % 3600) / 60
    remaining_seconds = seconds % 60

    if hours > 0
      "#{hours}h:#{minutes}m"
    elsif minutes > 0
      "#{minutes}m:#{remaining_seconds}s"
    else
      "#{remaining_seconds}s"
    end
  end
end
