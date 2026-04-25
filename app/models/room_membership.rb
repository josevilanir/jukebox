class RoomMembership < ApplicationRecord
  belongs_to :room
  belongs_to :user

  validates :name, presence: true, length: { maximum: 30 }
end
