class QueueItem < ApplicationRecord
  belongs_to :room
  belongs_to :track
  belongs_to :added_by, class_name: "User"
  has_many :votes, dependent: :destroy

  after_commit :broadcast_updates

  def score
    votes.sum(:value)
  end

  private

  def broadcast_updates
    # Atualiza a fila
    broadcast_replace_to(
      room,
      target: "queue",
      partial: "rooms/queue",
      locals: { room: room }
    )
    # Atualiza o player
    broadcast_replace_to(
      room,
      target: "player",
      partial: "rooms/player",
      locals: { room: room }
    )
  end
end
