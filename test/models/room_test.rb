require "test_helper"

class RoomTest < ActiveSupport::TestCase
  # ---- host? ----

  test "host? returns true for the room owner" do
    room = rooms(:active_room)
    assert room.host?(users(:host_user))
  end

  test "host? returns false for a non-owner user" do
    room = rooms(:active_room)
    refute room.host?(users(:guest_user))
  end

  test "host? returns false for nil user" do
    refute rooms(:active_room).host?(nil)
  end

  # ---- closed? ----

  test "closed? returns true for a closed room" do
    assert rooms(:closed_room).closed?
  end

  test "closed? returns false for an active room" do
    refute rooms(:active_room).closed?
  end

  # ---- can_advance? ----

  test "can_advance? returns true for host regardless of dj_mode" do
    room = rooms(:active_room)
    assert room.can_advance?(users(:host_user))
  end

  test "can_advance? returns true for non-host when dj_mode is on" do
    room = rooms(:dj_room)
    assert room.can_advance?(users(:guest_user))
  end

  test "can_advance? returns false for non-host when dj_mode is off and host is online" do
    # Use a fresh instance to avoid memoized @host_online from a previous test
    room = Room.find(rooms(:active_room).id)
    set_key = "presence:#{room.slug}"
    Rails.cache.write(set_key, {
      users(:host_user).id.to_s => { name: "Host User", at: Time.current.to_i }
    }, expires_in: 1.hour)

    refute room.can_advance?(users(:guest_user))

    Rails.cache.delete(set_key)
  end

  test "can_advance? returns true for non-host when host is offline (auto DJ mode)" do
    room = rooms(:active_room)
    Rails.cache.delete("presence:#{room.slug}")
    assert room.can_advance?(users(:guest_user))
  end

  # ---- advance! ----

  test "advance! marks current item as played" do
    room = rooms(:active_room)
    current = queue_items(:playing_item)
    current.update!(played_at: nil, started_at: nil)

    room.advance!(current)
    assert_not_nil current.reload.played_at
  end

  test "advance! sets started_at on the next item" do
    room = rooms(:active_room)
    current = queue_items(:playing_item)
    next_item = queue_items(:queued_item)
    current.update!(played_at: nil)
    next_item.update!(played_at: nil, started_at: nil)

    room.advance!(current)
    assert_not_nil next_item.reload.started_at
  end

  # ---- slug uniqueness ----

  test "slug is generated from name on create" do
    room = Room.create!(name: "My Test Room", owner: users(:host_user))
    assert_equal "my-test-room", room.slug
  end

  test "slug gets a counter suffix when name is taken" do
    # Close the first room so the name uniqueness check (active rooms only) passes for the second
    room1 = Room.create!(name: "Duplicate Room", owner: users(:host_user))
    room1.update_column(:status, "closed")
    room2 = Room.create!(name: "Duplicate Room", owner: users(:guest_user))
    assert_equal "duplicate-room-2", room2.slug
  end

  test "cannot create two active rooms with the same name" do
    room = Room.new(name: "Rock Room", owner: users(:guest_user))
    refute room.valid?
    assert_includes room.errors[:name], "Sala com esse nome já existe"
  end
end
