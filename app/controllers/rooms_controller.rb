class RoomsController < ApplicationController
  before_action :set_room, only: %i[show history play_next toggle_dj_mode close seek]
  before_action :redirect_if_closed, only: %i[show]

  def index
    @rooms = Room.where(status: "active").order(created_at: :desc)
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

  def history
    @pagy, @history_items = pagy(:offset, @room.history, limit: 10)
    render partial: "rooms/history", locals: { room: @room, pagy: @pagy, history_items: @history_items }
  end

  def play_next
    unless @room.can_advance?(current_user)
      redirect_to room_path(@room.slug), alert: "Apenas o host pode tocar a próxima (Modo DJ desligado)." and return
    end

    current = @room.now_playing
    if current
      @room.advance!(current)
      notice = "Avançou para a próxima."
    else
      notice = "Não há itens na fila."
    end
    redirect_to room_path(@room.slug), notice: notice
  end

  def seek
    return head :forbidden unless @room.host?(current_user)

    current = @room.now_playing
    return head :no_content unless current&.started_at

    # Client sends its current playback position; we derive started_at from it
    # so every connected client can independently compute the same elapsed time.
    current_time = params[:current_time].to_f
    new_started_at = Time.current - current_time.seconds
    current.update_columns(started_at: new_started_at)

    Turbo::StreamsChannel.broadcast_replace_to(
      @room,
      target: "player-seek",
      partial: "rooms/player_seek",
      locals: { started_at: new_started_at.to_i }
    )

    head :no_content
  end

  def close
    unless @room.host?(current_user)
      redirect_to room_path(@room.slug), alert: "Apenas o host pode fechar a sala." and return
    end

    @room.update!(status: "closed")
    redirect_to rooms_path, notice: "Sala '#{@room.name}' fechada."
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

  def redirect_if_closed
    return unless @room.closed? && !@room.host?(current_user)

    redirect_to rooms_path, alert: "Essa sala foi encerrada pelo host."
  end

  def room_params
    params.require(:room).permit(:name)
  end
end
