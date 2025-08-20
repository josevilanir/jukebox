class Room < ApplicationRecord
  has_many :queue_items, dependent: :destroy
  has_many :messages, dependent: :destroy

  validates :name, presence: true
  validates :slug, presence: true, uniqueness: true

  before_validation :ensure_slug

  # Ordena por score desc e desempata pelo mais antigo
  def ordered_queue
    queue_items.left_joins(:votes)
               .select("queue_items.*, COALESCE(SUM(votes.value),0) AS score")
               .group("queue_items.id")
               .order("score DESC, queue_items.created_at ASC")
  end

  private

  def ensure_slug
    self.slug = name.to_s.parameterize if slug.blank? && name.present?
  end
end
