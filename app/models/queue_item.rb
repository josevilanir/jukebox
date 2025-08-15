class QueueItem < ApplicationRecord
  belongs_to :room
  belongs_to :track
  belongs_to :added_by, class_name: "User"
  has_many :votes, dependent: :destroy

  # Atualiza a fila da sala via Turbo após mudanças
  after_commit :broadcast_queue_update

  def score
    votes.sum(:value)
  end

  private

  def broadcast_queue_update
    broadcast_replace_to(
      room,
      target: "queue",
      partial: "rooms/queue",
      locals: { room: room }
    )
  end
end
