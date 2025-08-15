# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.0].define(version: 2025_08_15_152000) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "queue_items", force: :cascade do |t|
    t.bigint "room_id", null: false
    t.bigint "track_id", null: false
    t.bigint "added_by_id", null: false
    t.integer "position", default: 0, null: false
    t.datetime "played_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["added_by_id"], name: "index_queue_items_on_added_by_id"
    t.index ["room_id", "position"], name: "index_queue_items_on_room_id_and_position"
    t.index ["room_id"], name: "index_queue_items_on_room_id"
    t.index ["track_id"], name: "index_queue_items_on_track_id"
  end

  create_table "rooms", force: :cascade do |t|
    t.string "name", null: false
    t.string "slug", null: false
    t.string "status", default: "active", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["slug"], name: "index_rooms_on_slug", unique: true
  end

  create_table "tracks", force: :cascade do |t|
    t.string "title", null: false
    t.string "artist"
    t.string "source", null: false
    t.string "external_id", null: false
    t.integer "duration"
    t.string "thumbnail_url"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["external_id"], name: "index_tracks_on_external_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "votes", force: :cascade do |t|
    t.bigint "queue_item_id", null: false
    t.bigint "user_id", null: false
    t.integer "value", default: 1, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["queue_item_id", "user_id"], name: "index_votes_on_queue_item_id_and_user_id", unique: true
    t.index ["queue_item_id"], name: "index_votes_on_queue_item_id"
    t.index ["user_id"], name: "index_votes_on_user_id"
  end

  add_foreign_key "queue_items", "rooms"
  add_foreign_key "queue_items", "tracks"
  add_foreign_key "queue_items", "users", column: "added_by_id"
  add_foreign_key "votes", "queue_items"
  add_foreign_key "votes", "users"
end
