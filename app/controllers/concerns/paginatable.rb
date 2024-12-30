# Provides pagination functionality for controllers.
#
# This concern adds methods to handle pagination of collections in a consistent way
# across the application. It supports both regular HTML responses and Turbo Frame
# updates for seamless client-side updates.
#
# @example Basic usage in a controller
#   class VideosController < ApplicationController
#     include Paginatable
#
#     def index
#       all_videos = Video.all
#       @videos = paginate(all_videos, per_page: 12)
#       respond_with_pagination(turbo_frame_id: "videos_content") { "videos/content" }
#     end
#   end
#
# @example Usage in a view with Turbo Frames
#   <%= turbo_frame_tag "videos_content" do %>
#     <% @videos.each do |video| %>
#       <%= render "video", video: video %>
#     <% end %>
#
#     <% if pagination_data[:total_pages] > 1 %>
#       <%= render "shared/pagination",
#             current_page: pagination_data[:page],
#             total_pages: pagination_data[:total_pages],
#             path: videos_path %>
#     <% end %>
#   <% end %>
module Paginatable
  extend ActiveSupport::Concern

  included do
    # Make pagination helpers available in views
    helper_method :paginate, :pagination_data
  end

  private

  # Paginates a collection and sets up pagination metadata.
  #
  # @param collection [Array, ActiveRecord::Relation] The collection to paginate
  # @param per_page [Integer] Number of items per page (default: 12)
  # @return [Array] The paginated collection
  def paginate(collection, per_page: 12)
    @page = (params[:page] || 1).to_i
    @per_page = (params[:per_page] || per_page).to_i
    @offset = (@page - 1) * @per_page

    # Get total count for pagination
    @total_count = collection.size
    @total_pages = (@total_count.to_f / @per_page).ceil

    # Apply pagination to collection
    collection.slice(@offset, @per_page) || []
  end

  # Returns a hash of pagination metadata for use in views and APIs.
  #
  # @return [Hash] Pagination metadata including:
  #   - page: Current page number
  #   - per_page: Items per page
  #   - total_count: Total number of items
  #   - total_pages: Total number of pages
  #   - offset: Current offset in the collection
  #   - first_item: Index of first item on current page
  #   - last_item: Index of last item on current page
  #   - has_next_page: Whether there is a next page
  #   - has_previous_page: Whether there is a previous page
  def pagination_data
    {
      page: @page,
      per_page: @per_page,
      total_count: @total_count,
      total_pages: @total_pages,
      offset: @offset,
      first_item: @offset + 1,
      last_item: [ @offset + @per_page, @total_count ].min,
      has_next_page: @page < @total_pages,
      has_previous_page: @page > 1
    }
  end

  # Handles response format for paginated content.
  #
  # @param turbo_frame_id [String, nil] ID of the Turbo Frame to update
  # @yield Block that returns the partial path or data to render
  # @example
  #   respond_with_pagination(turbo_frame_id: "content") { "videos/content" }
  def respond_with_pagination(turbo_frame_id: nil)
    respond_to do |format|
      format.html
      format.json { render json: { data: yield, pagination: pagination_data } } if block_given?
      if turbo_frame_id
        format.turbo_stream { render turbo_stream: turbo_stream.update(turbo_frame_id, partial: yield) }
      end
    end
  end
end
