class RoomsController < ApplicationController
  before_action :set_room, only: :show

  def index
    @rooms = Room.order(created_at: :desc)
  end

  def new
    @room = Room.new
  end

  def create
    @room = Room.new(room_params)
    if @room.save
      redirect_to room_path(@room.slug), notice: "Sala criada!"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def show
  end

  private

  def set_room
    @room = Room.find_by!(slug: params[:slug])
  end

  def room_params
    params.require(:room).permit(:name)
  end
end
