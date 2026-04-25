require "test_helper"

class MessagesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @room = rooms(:active_room)
    # Trigger ensure_current_user so a session user is created
    get rooms_path
    @current_user = User.find(session[:user_id])
    # Clear any fixture skip votes to isolate tests
    SkipVote.delete_all
  end

  test "normal message is saved as a user message" do
    assert_difference("Message.user_messages.count", 1) do
      post room_messages_path(@room.slug), params: { content: "Hello!" }
    end
    msg = Message.user_messages.last
    assert_equal "Hello!", msg.content
    assert_not msg.system?
    assert_equal @current_user, msg.user
  end

  test "/skip creates a skip vote and broadcasts a skip_vote system message" do
    assert_difference("SkipVote.count", 1) do
      post room_messages_path(@room.slug), params: { content: "/skip" }
    end

    skip_msg = Message.system_messages.where(system_type: "skip_vote").last
    assert_not_nil skip_msg
    assert_includes skip_msg.content, "votou para pular"
    assert skip_msg.system?
    assert_nil skip_msg.user_id
  end

  test "/skip when already voted broadcasts error system message without creating a new vote" do
    # Pre-create a vote bypassing callbacks to avoid triggering track advance
    queue_item = queue_items(:playing_item)
    SkipVote.insert({ queue_item_id: queue_item.id, user_id: @current_user.id,
                      created_at: Time.current, updated_at: Time.current })

    before_count = SkipVote.count
    assert_difference("Message.system_messages.count", 1) do
      post room_messages_path(@room.slug), params: { content: "/skip" }
    end
    assert_equal before_count, SkipVote.count

    msg = Message.system_messages.last
    assert_includes msg.content, "já votou"
  end

  test "/help broadcasts help system message" do
    assert_difference("Message.system_messages.count", 1) do
      post room_messages_path(@room.slug), params: { content: "/help" }
    end

    msg = Message.system_messages.last
    assert_includes msg.content, "/skip"
    assert_equal "help", msg.system_type
    assert msg.system?
    assert_nil msg.user_id
  end

  test "unknown command broadcasts error system message" do
    assert_difference("Message.system_messages.count", 1) do
      post room_messages_path(@room.slug), params: { content: "/unknown" }
    end

    msg = Message.system_messages.last
    assert_includes msg.content, "Comando não reconhecido"
    assert_equal "unknown_command", msg.system_type
    assert msg.system?
  end

  test "/skip with no playing track broadcasts error system message" do
    empty_room = rooms(:dj_room)

    assert_no_difference("SkipVote.count") do
      assert_difference("Message.system_messages.count", 1) do
        post room_messages_path(empty_room.slug), params: { content: "/skip" }
      end
    end

    msg = Message.system_messages.last
    assert_includes msg.content, "Nenhuma música"
  end
end
