require "test_helper"

class VoteTest < ActiveSupport::TestCase
  test "value must be 1" do
    vote = Vote.new(user: users(:guest_user), queue_item: queue_items(:playing_item), value: -1)
    refute vote.valid?
    assert_includes vote.errors[:value], "is not included in the list"

    vote.value = 1
    assert vote.valid?
  end

  test "user cannot vote twice on the same queue item" do
    qi = queue_items(:playing_item)
    Vote.create!(user: users(:guest_user), queue_item: qi, value: 1)

    duplicate = Vote.new(user: users(:guest_user), queue_item: qi, value: 1)
    refute duplicate.valid?
    assert_includes duplicate.errors[:user_id], "has already been taken"
  end

  test "different users can vote on the same queue item" do
    qi = queue_items(:playing_item)
    Vote.create!(user: users(:guest_user), queue_item: qi, value: 1)

    vote2 = Vote.new(user: users(:host_user), queue_item: qi, value: 1)
    assert vote2.valid?
  end
end
