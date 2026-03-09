class SkipVotesController < ApplicationController
  before_action :set_room_and_item

  def create
    unless @room.now_playing&.id == @queue_item.id
      redirect_to room_path(@room.slug), alert: "Só dá pra pular a música atual." and return
    end

    vote = @queue_item.skip_votes.find_or_initialize_by(user: current_user)

    if vote.new_record?
      vote.save!
      respond_to do |format|
        format.html { redirect_to room_path(@room.slug) }
        format.turbo_stream
      end
    else
      redirect_to room_path(@room.slug), notice: "Você já votou para pular."
    end
  end

  private

  def set_room_and_item
    @room       = Room.find_by!(slug: params[:room_slug])
    @queue_item = @room.queue_items.find(params[:queue_item_id])
  end
end
