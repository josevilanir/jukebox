class RoomSearchesController < ApplicationController
  before_action :set_room

  def show
    query = params[:query]
    if query.present?
      @results = YoutubeSearchService.search(query)
    else
      @results = []
    end

    respond_to do |format|
      format.turbo_stream
    end
  end

  private

  def set_room
    @room = Room.find_by!(slug: params[:room_slug])
  end
end
