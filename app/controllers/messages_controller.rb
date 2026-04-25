class MessagesController < ApplicationController
  before_action :set_room

  def create
    content = params[:content].to_s.strip

    if content.start_with?("/")
      handle_slash_command(content)
      respond_to do |format|
        format.html { redirect_to room_path(@room.slug) }
        format.turbo_stream { head :ok }
      end
      return
    end

    @message = @room.messages.build(content: content, user: current_user)

    if @message.save
      respond_to do |format|
        format.html { redirect_to room_path(@room.slug) }
        format.turbo_stream
      end
    else
      redirect_to room_path(@room.slug), alert: @message.errors.full_messages.to_sentence
    end
  end

  private

  def handle_slash_command(content)
    command = content.split(" ", 2).first.downcase

    case command
    when "/skip"
      handle_skip_command
    when "/help"
      Message.broadcast_system_to(
        @room,
        content: "/skip — votar para pular a música atual",
        system_type: "help"
      )
    else
      Message.broadcast_system_to(
        @room,
        content: "Comando não reconhecido. Digite /help para ver os comandos disponíveis.",
        system_type: "unknown_command"
      )
    end
  end

  def handle_skip_command
    queue_item = @room.now_playing

    unless queue_item
      Message.broadcast_system_to(
        @room,
        content: "Nenhuma música tocando no momento.",
        system_type: "skip_error"
      )
      return
    end

    vote = queue_item.skip_votes.find_or_initialize_by(user: current_user)

    if vote.new_record?
      vote.save!
      Message.broadcast_system_to(
        @room,
        content: "⏭ #{current_user.name_in(@room)} votou para pular.",
        system_type: "skip_vote"
      )
    else
      Message.broadcast_system_to(
        @room,
        content: "Você já votou para pular.",
        system_type: "skip_error"
      )
    end
  end

  def set_room
    @room = Room.find_by!(slug: params[:room_slug])
  end
end
