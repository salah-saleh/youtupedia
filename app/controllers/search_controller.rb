# frozen_string_literal: true

class SearchController < ApplicationController
  include SearchableVideos
  include RequestLockable
  requires_lock_for :index, lock_name: :search, timeout: 1.minutes

  def index
    @query = params[:q]
    @search_terms = @query.present? ? @query.split(/\s+/) : []
    @videos = @query.present? ? search_videos(@query) : []

    respond_to do |format|
      format.html
      format.turbo_stream
    end
  end
end
