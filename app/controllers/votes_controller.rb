class VotesController < ApplicationController
  before_action :set_queue_item

  def create
    vote = current_user.votes.find_or_initialize_by(queue_item: @queue_item)
    vote.value = 1
    vote.save!

    respond_to do |format|
      format.html { redirect_to room_path(@queue_item.room.slug) }
      format.turbo_stream
    end
  end

  def destroy
    current_user.votes.where(queue_item: @queue_item).destroy_all

    respond_to do |format|
      format.html { redirect_to room_path(@queue_item.room.slug) }
      format.turbo_stream
    end
  end

  private

  def set_queue_item
    @queue_item = QueueItem.find(params[:queue_item_id])
  end
end
