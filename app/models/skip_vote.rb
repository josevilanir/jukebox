class SkipVote < ApplicationRecord
  belongs_to :queue_item
  belongs_to :user

  validates :user_id, uniqueness: { scope: :queue_item_id }

  after_create_commit :check_threshold

  private

  def check_threshold
    room = queue_item.room
    present_count = PresenceChannel.user_count(room.slug)
    skip_count    = queue_item.skip_votes.count

    # Threshold: 50% dos presentes, mínimo 2 votos para não pular sozinho
    threshold = [[(present_count * 0.5).ceil, 2].max, [present_count, 1].max].min

    queue_item.update!(played_at: Time.current) if skip_count >= threshold
  end
end
