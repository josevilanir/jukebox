class User < ApplicationRecord
  has_many :queue_items, foreign_key: :added_by_id, dependent: :nullify
  has_many :votes, dependent: :destroy
  has_many :skip_votes, dependent: :destroy

  validates :name, presence: true, length: { maximum: 30 }
end
