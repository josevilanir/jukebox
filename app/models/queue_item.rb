class QueueItem < ApplicationRecord
  belongs_to :room
  belongs_to :track
  belongs_to :added_by, class_name: "User"
  has_many :votes, dependent: :destroy
  has_many :skip_votes, dependent: :destroy

  before_create :assign_started_at_if_first
  after_commit :broadcast_updates

  def score
    votes.sum(:value)
  end

  private

  def assign_started_at_if_first
    # If the queue is empty this item will immediately be now_playing
    self.started_at = Time.current if room.now_playing.nil?
  end

  def broadcast_updates
    broadcast_update_to(
      room,
      target: "queue",
      partial: "rooms/queue",
      locals: { room: room }
    )

    # Só atualiza o player quando a faixa em execução muda:
    # - played_at foi definido (play_next ou skip vote atingiu threshold)
    # - item foi destruído
    # - é o primeiro item da fila (sala estava vazia)
    return unless saved_change_to_played_at? ||
                  destroyed? ||
                  (previously_new_record? && room.queue_open.length == 1)

    broadcast_replace_to(
      room,
      target: "player",
      partial: "rooms/player",
      locals: { room: room }
    )

    next_playing = room.now_playing
    if next_playing
      Message.broadcast_system_to(
        room,
        content: "🎵 Tocando agora: #{next_playing.track.title}",
        system_type: "now_playing"
      )
    end
  end
end
