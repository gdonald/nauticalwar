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

ActiveRecord::Schema[7.0].define(version: 18) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "enemies", force: :cascade do |t|
    t.integer "player1_id", null: false
    t.integer "player2_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["player1_id", "player2_id"], name: "index_enemies_on_player1_id_and_player2_id", unique: true
  end

  create_table "friends", force: :cascade do |t|
    t.integer "player1_id", null: false
    t.integer "player2_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["player1_id", "player2_id"], name: "index_friends_on_player1_id_and_player2_id", unique: true
  end

  create_table "games", force: :cascade do |t|
    t.integer "player1_id", null: false
    t.integer "player2_id", null: false
    t.boolean "player1_layed_out", default: false, null: false
    t.boolean "player2_layed_out", default: false, null: false
    t.boolean "rated", default: false, null: false
    t.integer "time_limit", null: false
    t.integer "turn_id", null: false
    t.integer "winner_id"
    t.boolean "del_player1", default: false, null: false
    t.boolean "del_player2", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "shots_per_turn"
    t.index ["player1_id"], name: "index_games_on_player1_id"
    t.index ["player2_id"], name: "index_games_on_player2_id"
  end

  create_table "invites", force: :cascade do |t|
    t.integer "player1_id", null: false
    t.integer "player2_id", null: false
    t.boolean "rated", default: true, null: false
    t.integer "time_limit", default: 60, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "shots_per_turn"
    t.index ["player1_id", "player2_id"], name: "index_invites_on_player1_id_and_player2_id", unique: true
  end

  create_table "layouts", force: :cascade do |t|
    t.integer "game_id", null: false
    t.integer "player_id", null: false
    t.integer "ship_id", null: false
    t.integer "x", null: false
    t.integer "y", null: false
    t.boolean "vertical", default: false, null: false
    t.boolean "sunk", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["player_id", "game_id", "x", "y"], name: "index_layouts_on_player_id_and_game_id_and_x_and_y", unique: true
    t.index ["sunk"], name: "index_layouts_on_sunk"
  end

  create_table "moves", force: :cascade do |t|
    t.integer "game_id", null: false
    t.integer "player_id", null: false
    t.integer "layout_id"
    t.integer "x", null: false
    t.integer "y", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["game_id", "player_id", "x", "y"], name: "index_moves_on_game_id_and_player_id_and_x_and_y", unique: true
  end

  create_table "players", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "name", default: "", null: false
    t.string "p_salt", limit: 80
    t.string "p_hash", limit: 80
    t.boolean "bot", default: false, null: false
    t.integer "strength", default: 0, null: false
    t.integer "wins", default: 0, null: false
    t.integer "losses", default: 0, null: false
    t.integer "activity", default: 0, null: false
    t.integer "rating", default: 1200, null: false
    t.boolean "admin", default: false, null: false
    t.string "password_token"
    t.datetime "password_token_expire", precision: nil
    t.string "confirmation_token"
    t.datetime "confirmed_at", precision: nil
    t.datetime "last_sign_in_at", precision: nil
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "guest", default: false, null: false
    t.boolean "hints", default: true, null: false
    t.integer "water", default: 0, null: false
    t.integer "grid", default: 1, null: false
    t.string "unsub_hash"
    t.index ["email"], name: "index_players_on_email", unique: true
    t.index ["name"], name: "index_players_on_name", unique: true
    t.index ["rating"], name: "index_players_on_rating"
  end

  create_table "ships", force: :cascade do |t|
    t.string "name", limit: 12
    t.integer "size"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "unsubs", force: :cascade do |t|
    t.string "email", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_unsubs_on_email", unique: true
  end

end
