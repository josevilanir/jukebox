require "test_helper"

class SkipVoteTest < ActiveSupport::TestCase
  test "user cannot vote twice on the same queue item" do
    qi = queue_items(:playing_item)
    # guest_user já votou via fixture
    duplicate = SkipVote.new(queue_item: qi, user: users(:guest_user))
    refute duplicate.valid?
  end

  test "different users can vote on the same queue item" do
    qi = queue_items(:playing_item)
    vote = SkipVote.new(queue_item: qi, user: users(:third_user))
    assert vote.valid?
  end

  test "threshold reached advances the queue" do
    room = rooms(:active_room)
    qi = queue_items(:playing_item)
    qi.update!(played_at: nil)

    # Simula 2 pessoas presentes na sala
    Rails.cache.write("presence:#{room.slug}", {
      users(:host_user).id.to_s  => { name: "Host", at: Time.current.to_i },
      users(:guest_user).id.to_s => { name: "Guest", at: Time.current.to_i }
    }, expires_in: 1.hour)

    # guest_user já votou na fixture — vota o host_user para atingir 2/2
    SkipVote.create!(queue_item: qi, user: users(:host_user))

    assert_not_nil qi.reload.played_at

    Rails.cache.delete("presence:#{room.slug}")
  end
end
