require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "name cannot exceed 30 characters" do
    user = User.new(name: "a" * 31)
    refute user.valid?
  end

  test "name_set defaults to false" do
    user = User.create!(name: "Test User")
    refute user.name_set?
  end
end
