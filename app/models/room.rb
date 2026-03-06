class Room < ApplicationRecord
  belongs_to :owner, class_name: "User", optional: true

  has_many :queue_items, dependent: :destroy
  has_many :messages, dependent: :destroy

  validates :name, presence: true
  validates :slug, presence: true, uniqueness: true
  validate :name_unique_among_active_rooms, on: :create

  before_validation :ensure_slug

  # ---- Fila / Player ----
  def queue_open
    queue_items.where(played_at: nil)
               .left_joins(:votes)
               .select("queue_items.*, COALESCE(SUM(votes.value),0) AS score")
               .group("queue_items.id")
               .order("score DESC, queue_items.created_at ASC")
  end

  def now_playing
    queue_open.first
  end

  def history(limit: 20)
    queue_items.where.not(played_at: nil)
               .order(played_at: :desc)
               .limit(limit)
  end

  # ---- Permissões ----
  def host?(user)
    user.present? && owner_id.present? && owner_id == user.id
  end

  def host_online?
    return false unless owner_id.present?

    set = Rails.cache.read("presence:#{slug}") || {}
    cutoff = 40.seconds.ago.to_i
    set.key?(owner_id.to_s) && set[owner_id.to_s][:at] >= cutoff
  end

  def dj_mode_active?
    dj_mode? || !host_online?
  end

  def can_advance?(user)
    host?(user) || dj_mode_active?
  end

  def closed?
    status == "closed"
  end

  # Marks current_item as played and timestamps the next song so
  # late-joining users can seek to the correct position.
  def advance!(current_item)
    next_item = queue_open.second
    next_item&.update_columns(started_at: Time.current)
    current_item.update!(played_at: Time.current)
  end

  private

  def name_unique_among_active_rooms
    return if name.blank?

    if Room.where(status: "active").where("LOWER(name) = ?", name.downcase).where.not(id: id).exists?
      errors.add(:name, "Sala com esse nome já existe")
    end
  end

  def ensure_slug
    return if slug.present? || name.blank?

    base = name.parameterize
    candidate = base
    counter = 2
    while Room.where(slug: candidate).where.not(id: id).exists?
      candidate = "#{base}-#{counter}"
      counter += 1
    end
    self.slug = candidate
  end
end
