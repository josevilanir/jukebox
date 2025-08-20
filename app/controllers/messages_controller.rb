class MessagesController < ApplicationController
  before_action :set_room

  def create
    @message = @room.messages.build(content: params[:content], user: current_user)

    if @message.save
      respond_to do |format|
        format.html { redirect_to room_path(@room.slug) }
        format.turbo_stream # o broadcast do model já cuida de atualizar
      end
    else
      redirect_to room_path(@room.slug), alert: @message.errors.full_messages.to_sentence
    end
  end

  private

  def set_room
    @room = Room.find_by!(slug: params[:room_slug])
  end
end
