class User < ApplicationRecord
  has_many :queue_items, foreign_key: :added_by_id, dependent: :nullify
  has_many :votes, dependent: :destroy
  has_many :skip_votes, dependent: :destroy
  has_many :room_memberships, dependent: :destroy

  validates :name, length: { maximum: 30 }, allow_blank: true

  def name_in(room)
    room_memberships.find_by(room: room)&.name || "Visitante"
  end
end
