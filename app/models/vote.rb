class Vote < ApplicationRecord
  belongs_to :queue_item
  belongs_to :user

  validates :value, inclusion: { in: [1] } # só upvote por enquanto
  validates :user_id, uniqueness: { scope: :queue_item_id }

  after_commit :notify_room

  private

  def notify_room
    # Atualiza fila e player após votar / remover voto
    queue_item.send(:broadcast_updates)
  end
end
