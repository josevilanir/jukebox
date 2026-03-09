require "test_helper"

class RoomsControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get rooms_path
    assert_response :success
  end

  test "should get new" do
    get new_room_path
    assert_response :success
  end

  test "should get create" do
    post rooms_path, params: { room: { name: "Test Room" } }
    assert_response :redirect
  end

  test "should get show" do
    room = rooms(:active_room)
    get room_path(room.slug)
    assert_response :success
  end
end
