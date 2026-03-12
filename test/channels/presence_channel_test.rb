require "test_helper"

class PresenceChannelTest < ActionCable::Channel::TestCase
  def setup
    @user = users(:host_user)
    @room = rooms(:active_room)
    stub_connection current_user: @user
  end

  # ---- subscribed ----

  test "subscribed streams from the room's presence stream" do
    subscribe room_slug: @room.slug
    assert_has_stream "presence:#{@room.slug}"
  end

  test "subscribed adds the user to the presence cache" do
    subscribe room_slug: @room.slug

    set = Rails.cache.read("presence:#{@room.slug}")
    assert_not_nil set
    assert set.key?(@user.id.to_s), "Expected user to be present in cache"
    assert_in_delta Time.current.to_i, set[@user.id.to_s][:at], 5
  end

  test "subscribed broadcasts a presence count update" do
    assert_broadcasts("presence:#{@room.slug}", 1) do
      subscribe room_slug: @room.slug
    end
  end

  test "subscribed broadcast includes the current count" do
    messages = []
    subscription = ActionCable.server.pubsub
    # Write a second user to cache first so count > 1
    other = users(:guest_user)
    Rails.cache.write(
      "presence:#{@room.slug}",
      { other.id.to_s => { name: other.name, at: Time.current.to_i } },
      expires_in: 1.hour
    )

    assert_broadcast_on("presence:#{@room.slug}", { "count" => 2 }) do
      subscribe room_slug: @room.slug
    end
  end

  # ---- unsubscribed ----

  test "unsubscribed removes the user from the presence cache" do
    subscribe room_slug: @room.slug
    unsubscribe

    set = Rails.cache.read("presence:#{@room.slug}") || {}
    refute set.key?(@user.id.to_s), "Expected user to be removed from cache"
  end

  test "unsubscribed broadcasts a count update" do
    subscribe room_slug: @room.slug

    assert_broadcasts("presence:#{@room.slug}", 1) do
      unsubscribe
    end
  end

  # ---- heartbeat ----

  test "heartbeat updates the user's timestamp in the cache" do
    subscribe room_slug: @room.slug

    # Force a stale timestamp
    stale_time = 30.seconds.ago.to_i
    set = Rails.cache.read("presence:#{@room.slug}")
    set[@user.id.to_s][:at] = stale_time
    Rails.cache.write("presence:#{@room.slug}", set, expires_in: 1.hour)

    perform :heartbeat, {}

    updated_set = Rails.cache.read("presence:#{@room.slug}")
    assert_in_delta Time.current.to_i, updated_set[@user.id.to_s][:at], 5
  end

  # ---- user_count ----

  test "user_count returns 0 for an empty cache" do
    Rails.cache.delete("presence:#{@room.slug}")
    assert_equal 0, PresenceChannel.user_count(@room.slug)
  end

  test "user_count returns 0 when all entries are stale" do
    stale_at = 41.seconds.ago.to_i
    Rails.cache.write(
      "presence:#{@room.slug}",
      { @user.id.to_s => { name: @user.name, at: stale_at } },
      expires_in: 1.hour
    )
    assert_equal 0, PresenceChannel.user_count(@room.slug)
  end

  test "user_count returns the correct count for active users" do
    other = users(:guest_user)
    Rails.cache.write(
      "presence:#{@room.slug}",
      {
        @user.id.to_s  => { name: @user.name,  at: Time.current.to_i },
        other.id.to_s  => { name: other.name,  at: Time.current.to_i }
      },
      expires_in: 1.hour
    )
    assert_equal 2, PresenceChannel.user_count(@room.slug)
  end

  test "user_count ignores stale entries and counts only fresh ones" do
    other = users(:guest_user)
    Rails.cache.write(
      "presence:#{@room.slug}",
      {
        @user.id.to_s  => { name: @user.name,  at: Time.current.to_i },
        other.id.to_s  => { name: other.name,  at: 41.seconds.ago.to_i }
      },
      expires_in: 1.hour
    )
    assert_equal 1, PresenceChannel.user_count(@room.slug)
  end
end
