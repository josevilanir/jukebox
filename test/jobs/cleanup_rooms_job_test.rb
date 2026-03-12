require "test_helper"

class CleanupRoomsJobTest < ActiveSupport::TestCase
  setup do
    @room  = rooms(:active_room)
    @track = tracks(:youtube_track)
    @user  = users(:guest_user)
  end

  test "deletes played items older than 30 days" do
    old_item = QueueItem.create!(room: @room, track: @track, added_by: @user,
                                  position: 99, played_at: 31.days.ago)

    CleanupRoomsJob.new.perform

    assert_not QueueItem.exists?(old_item.id)
  end

  test "does not delete played items within the last 30 days" do
    recent_item = QueueItem.create!(room: @room, track: @track, added_by: @user,
                                     position: 98, played_at: 29.days.ago)

    CleanupRoomsJob.new.perform

    assert QueueItem.exists?(recent_item.id)
  end

  test "does not delete unplayed items regardless of age" do
    unplayed_item = QueueItem.create!(room: @room, track: @track, added_by: @user,
                                       position: 97, played_at: nil)

    CleanupRoomsJob.new.perform

    assert QueueItem.exists?(unplayed_item.id)
  end
end
