class Room < ApplicationRecord
  has_many :queue_items, dependent: :destroy
  has_many :messages, dependent: :destroy

  validates :name, presence: true
  validates :slug, presence: true, uniqueness: true

  before_validation :ensure_slug

  # Itens ainda não tocados, ordenados por score DESC e primeiro a entrar
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

  private

  def ensure_slug
    self.slug = name.to_s.parameterize if slug.blank? && name.present?
  end
end
