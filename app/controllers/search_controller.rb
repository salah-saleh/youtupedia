class SearchController < ApplicationController
  include SearchableVideos
  include RequestLockable

  before_action :authenticate!
  requires_lock_for :index, lock_name: :search, timeout: 1.minutes
  layout "dashboard"

  def index
    @query = params[:q]

    if @query.present?
      @videos = search_videos(@query, Current.user.id)
      @search_terms = @query.split(/\s+/)
    else
      @videos = []
      @search_terms = []
    end

    respond_to do |format|
      format.html
      format.turbo_stream
    end
  end
end
