class CleanupRoomsJob < ApplicationJob
  queue_as :background

  def perform
    cutoff = 30.days.ago
    deleted_count = QueueItem.where("played_at < ?", cutoff).delete_all
    Rails.logger.info "[CleanupRoomsJob] Deleted #{deleted_count} played QueueItems older than 30 days"
  end
end
