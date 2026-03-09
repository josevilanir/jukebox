class Message < ApplicationRecord
  belongs_to :room
  belongs_to :user

  validates :content, presence: true, length: { maximum: 1_000 }

  # publica a mensagem no alvo "messages" da sala
  after_create_commit do
    broadcast_append_to room, target: "messages", partial: "messages/message", locals: { message: self }
  end
end
