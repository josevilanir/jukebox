class QueueItem < ApplicationRecord
  belongs_to :room
  belongs_to :track
  belongs_to :added_by, class_name: "User"
  has_many :votes, dependent: :destroy
  has_many :skip_votes, dependent: :destroy

  after_commit :broadcast_updates

  def score
    votes.sum(:value)
  end

  private

  def broadcast_updates
    broadcast_replace_to(
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
  end
end
