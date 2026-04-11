class QueueItemsController < ApplicationController
  before_action :set_room

  def create
    begin
      if params[:youtube_id].present?
        track = Track.find_or_create_by!(source: "youtube", external_id: params[:youtube_id]) do |t|
          t.title = params[:title]
          t.thumbnail_url = params[:thumbnail_url]
        end
      else
        url_param = params[:url].to_s.strip
        if url_param.match?(/^https?:\/\//)
          track = Track.from_youtube_url(url_param)
        else
          # Fallback: Treat as a direct search query if the user hit Enter too fast
          results = YoutubeSearchService.search(url_param)
          if results.any?
            top = results.first
            track = Track.find_or_create_by!(source: "youtube", external_id: top[:id]) do |t|
              t.title = top[:title]
              t.thumbnail_url = top[:thumbnail_url]
            end
          else
            redirect_to room_path(@room.slug), alert: "Busca não encontrou resultados para: #{url_param}" and return
          end
        end
      end
    rescue ArgumentError, ActiveRecord::RecordInvalid => e
      redirect_to room_path(@room.slug), alert: e.message and return
    end

    unless YoutubeSearchService.embeddable?(track.external_id)
      redirect_to room_path(@room.slug), alert: "\"#{track.title}\" não pode ser incorporado (bloqueado pelo dono, ex: VEVO). Tente outra versão do vídeo." and return
    end

    existing = @room.queue_items.find_by(track: track, played_at: nil)
    if existing
      redirect_to room_path(@room.slug), notice: "Essa música já está na fila. 😉" and return
    end

    qi = @room.queue_items.create!(track: track, added_by: current_user)
    current_user.votes.create!(queue_item: qi, value: 1)

    respond_to do |format|
      format.html { redirect_to room_path(@room.slug), notice: "Música adicionada!" }
      format.turbo_stream
    end
  end

  def destroy
    qi = @room.queue_items.find(params[:id])
    if @room.host?(current_user) || qi.added_by_id == current_user.id
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
