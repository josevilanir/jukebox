class RoomMembershipsController < ApplicationController
  def create
    @room = Room.find_by!(slug: params[:room_slug])
    membership = current_user.room_memberships.build(room: @room, name: params[:name])
    if membership.save
      redirect_to room_path(@room.slug)
    else
      redirect_to room_path(@room.slug), alert: membership.errors.full_messages.to_sentence
    end
  end
end
