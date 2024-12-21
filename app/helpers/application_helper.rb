module ApplicationHelper
  def page_title
    base_title = "Y2SI"

    # Get title from content_for if set in the view
    custom_title = content_for(:page_title)
    return "#{custom_title} - #{base_title}" if custom_title.present?

    # Fallback to automatic title detection
    current_title = case
    when @metadata.present?
      @metadata[:metadata][:title]
    when @channel_name.present?
      @channel_name
    when params[:q].present? && current_page?(search_index_path)
        params[:q]
    else
        controller_name
    end

    current_title.present? ? "#{current_title.titleize} - #{base_title}" : base_title
  end
end
