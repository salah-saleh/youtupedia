module ApplicationHelper
  # used in determining the page title in the browser tab
  def page_title
    base_title = "Youtupedia"

    # Get title from content_for if set in the view
    custom_title = content_for(:page_title)
    return "#{custom_title} - #{base_title}" if custom_title.present?

    # Fallback to automatic title detection
    current_title = case
    when @metadata.present?
      @metadata[:metadata][:title]
    when @channel_name.present?
      @channel_name
    when params[:q].present?
        "Search: #{params[:q]}"
    else
        controller_name
    end

    current_title.present? ? "#{current_title.titleize} - #{base_title}" : base_title
  end

  # used in determining the aspect ratio of the image to reserve space for it
  def aspect_class(aspect)
    case aspect&.to_s
    when "square"
      "aspect-w-1 aspect-h-1"
    when "video"
      "aspect-w-16 aspect-h-9"
    else
      "aspect-w-16 aspect-h-9" # default to video aspect ratio
    end
  end

  def size_class(size)
    case size&.to_s
    when "sm"
      "w-32"  # 128px
    when "md"
      "w-48"  # 192px
    when "lg"
      "w-64"  # 256px
    when "full"
      "w-full"
    else
      "w-48"  # default to medium size
    end
  end
end
