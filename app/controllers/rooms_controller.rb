class RoomsController < ApplicationController
  before_action :set_room, only: %i[show play_next]

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
    @queue_items = @room.queue_open
    @current_item = @room.now_playing
  end

  # Marca o item atual como tocado; o próximo vira "now playing"
  def play_next
    current = @room.now_playing
    if current
      current.update!(played_at: Time.current)
      notice = "Avançou para a próxima."
    else
      notice = "Não há itens na fila."
    end
    redirect_to room_path(@room.slug), notice: notice
  end

  private

  def set_room
    @room = Room.find_by!(slug: params[:slug])
  end

  def room_params
    params.require(:room).permit(:name)
  end
end
