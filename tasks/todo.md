# TODO: Jukebox MVP — 4 Novas Features

## Branch: feature/mvp-4-features
## Status: DONE ✓

## Feature 1 — Nome de usuário ✓
- [x] Migration: add_name_set_to_users
- [x] Model: User — name_set column, validates name presence/length
- [x] Controller: UsersController#update
- [x] Routes: `resource :user, only: [:update]`
- [x] ApplicationController: update ensure_current_user + show_name_modal? helper
- [x] Layout: modal in application.html.erb
- [x] JS: name_modal_controller.js

## Feature 2 — Presença em tempo real ✓
- [x] Channel: PresenceChannel (with user_count class method)
- [x] JS: presence_controller.js + channels/consumer.js (ActionCable)
- [x] Importmap: pin @rails/actioncable + pin_all_from channels
- [x] View: rooms/show.html.erb — updated room header with presence controller

## Feature 3 — Votação de skip ✓
- [x] Migration: create_skip_votes
- [x] Model: SkipVote (with after_create_commit threshold check)
- [x] Model: QueueItem — has_many :skip_votes
- [x] Controller: SkipVotesController#create
- [x] Routes: nested skip_votes under queue_items
- [x] View: rooms/_player.html.erb — skip vote button
- [x] View: skip_votes/create.turbo_stream.erb

## Feature 4 — Modo DJ ✓
- [x] Migration: add_dj_mode_to_rooms
- [x] Model: Room — dj_mode_active?, host_online?, can_advance?
- [x] Controller: RoomsController — toggle_dj_mode + updated play_next
- [x] Routes: toggle_dj_mode member action
- [x] View: rooms/show.html.erb — DJ mode badge + toggle button

## Final ✓
- [x] bin/rails db:migrate — 3 migrations ran clean
- [x] bin/rails test — 5/5 tests pass
