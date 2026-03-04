class RoomsController < ApplicationController
  before_action :set_room, only: %i[show play_next toggle_dj_mode]

  def index
    @rooms = Room.order(created_at: :desc)
  end

  def new
    @room = Room.new
  end

  def create
    @room = Room.new(room_params)
    @room.owner = current_user
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

  def play_next
    unless @room.can_advance?(current_user)
      redirect_to room_path(@room.slug), alert: "Apenas o host pode tocar a próxima (Modo DJ desligado)." and return
    end

    current = @room.now_playing
    if current
      current.update!(played_at: Time.current)
      notice = "Avançou para a próxima."
    else
      notice = "Não há itens na fila."
    end
    redirect_to room_path(@room.slug), notice: notice
  end

  def toggle_dj_mode
    unless @room.host?(current_user)
      redirect_to room_path(@room.slug), alert: "Apenas o host pode alterar o Modo DJ." and return
    end

    @room.update!(dj_mode: !@room.dj_mode?)
    status = @room.dj_mode? ? "ativado" : "desativado"
    redirect_to room_path(@room.slug), notice: "Modo DJ #{status}."
  end

  private

  def set_room
    @room = Room.find_by!(slug: params[:slug])
  end

  def room_params
    params.require(:room).permit(:name)
  end
end
