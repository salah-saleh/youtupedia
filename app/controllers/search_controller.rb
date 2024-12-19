# frozen_string_literal: true

class SearchController < ApplicationController
  include SearchableVideos
  include RequestLockable
  requires_lock_for :index, lock_name: :search, timeout: 1.minutes

  def index
    @query = params[:q]
    @search_terms = @query.present? ? @query.split(/\s+/) : []
    @videos = @query.present? ? search_videos(@query) : []
  end

  def create_from_url
    @query = params[:q]
    redirect_to search_index_path(q: @query)
  end
end
