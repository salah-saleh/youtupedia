require "sitemap_generator"

# Set the host name for URL creation
SitemapGenerator::Sitemap.default_host = "https://youtupedia.com"

# The directory to write sitemaps to locally
SitemapGenerator::Sitemap.public_path = "public/"

# Store on S3 if using AWS
# SitemapGenerator::Sitemap.adapter = SitemapGenerator::S3Adapter.new(
#   aws_access_key_id: ENV["AWS_ACCESS_KEY"],
#   aws_secret_access_key: ENV["AWS_SECRET_KEY"],
#   fog_provider: "AWS",
#   fog_directory: ENV["S3_BUCKET"]
# )

# Inform the map cross-linking where to find the other maps
# SitemapGenerator::Sitemap.sitemaps_host = "http://s3.amazonaws.com/sitemap-generator/"

# Pick a place safe to write the files
# SitemapGenerator::Sitemap.public_path = "tmp/"

SitemapGenerator::Sitemap.create do
  # Add priority pages (root URL is added automatically)
  add "/channels", priority: 0.1, changefreq: "weekly"
  add "/summaries", priority: 0.1, changefreq: "weekly"
  add "/about", priority: 0.9, changefreq: "monthly"
  add "/contact", priority: 0.9, changefreq: "monthly"

  # Add dynamic channel pages
  channels = UserServices::UserDataService.user_items("master", :channels)
  puts "Found #{channels.length} channels for sitemap"
  
  channels.each do |channel_name|
    puts "Processing channel: #{channel_name}"
    channel = Youtube::YoutubeChannelService.fetch_channel_metadata(channel_name)
    
    if channel[:success]
      puts "Adding channel to sitemap: #{channel_name}"
      add "/channels/#{channel_name}", 
          priority: 0.8, 
          changefreq: "monthly",  # Content is mostly static once generated
          lastmod: Time.current  # Since we don"t store update times
    else
      puts "Failed to fetch channel metadata for: #{channel_name}"
    end
  end

  # Add dynamic summary pages
  summaries = UserServices::UserDataService.user_items("master", :summaries)
  puts "Found #{summaries.length} summaries for sitemap"
  
  summaries.each do |video_id|
    puts "Processing video: #{video_id}"
    metadata = Youtube::YoutubeVideoMetadataService.fetch_metadata(video_id)
    
    if metadata[:success]
      puts "Adding summary to sitemap: #{video_id}"
      add "/summaries/#{video_id}", 
          priority: 0.9, 
          changefreq: "monthly",  # Content is mostly static once generated
          lastmod: Time.current  # Since we don"t store update times
    else
      puts "Failed to fetch video metadata for: #{video_id}"
    end
    end

end 