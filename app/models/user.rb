class User < ApplicationRecord
  has_many :queue_items, foreign_key: :added_by_id, dependent: :nullify
  has_many :votes, dependent: :destroy
end