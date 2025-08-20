class QueueItemsController < ApplicationController
  before_action :set_room

  def create
    begin
      track = Track.from_youtube_url(params[:url])
    rescue => e
      redirect_to room_path(@room.slug), alert: e.message and return
    end

    # DEDUPE: se já existe esse vídeo na fila aberta, só mostra aviso
    existing = @room.queue_items.find_by(track: track, played_at: nil)
    if existing
      redirect_to room_path(@room.slug), notice: "Essa música já está na fila. 😉" and return
    end

    qi = @room.queue_items.create!(track: track, added_by: current_user)

    # AUTO-VOTO de quem adicionou
    current_user.votes.create!(queue_item: qi, value: 1)

    respond_to do |format|
      format.html { redirect_to room_path(@room.slug), notice: "Música adicionada!" }
      format.turbo_stream
    end
  end

  def destroy
    qi = @room.queue_items.find(params[:id])
    if qi.added_by_id == current_user.id
      qi.destroy
      redirect_to room_path(@room.slug), notice: "Removido da fila."
    else
      redirect_to room_path(@room.slug), alert: "Você não pode remover este item."
    end
  end

  private

  def set_room
    @room = Room.find_by!(slug: params[:room_slug])
  end
end
