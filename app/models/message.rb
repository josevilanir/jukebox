class Message < ApplicationRecord
  belongs_to :room
  belongs_to :user, optional: true

  validates :content, presence: true, length: { maximum: 1_000 }
  validates :user, presence: true, unless: :system?

  scope :user_messages, -> { where(system: [ false, nil ]) }
  scope :system_messages, -> { where(system: true) }

  after_create_commit do
    broadcast_append_to room, target: "messages", partial: "messages/message", locals: { message: self }
  end

  def system?
    system == true
  end

  def self.broadcast_system_to(room, content:, system_type: nil)
    room.messages.create!(
      content: content,
      system: true,
      system_type: system_type
    )
  end
end
