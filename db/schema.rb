# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 9) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "enemies", force: :cascade do |t|
    t.integer "user_1_id", null: false
    t.integer "user_2_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_1_id", "user_2_id"], name: "index_enemies_on_user_1_id_and_user_2_id", unique: true
  end

  create_table "friends", force: :cascade do |t|
    t.integer "user_1_id", null: false
    t.integer "user_2_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_1_id", "user_2_id"], name: "index_friends_on_user_1_id_and_user_2_id", unique: true
  end

  create_table "games", force: :cascade do |t|
    t.integer "user_1_id", null: false
    t.integer "user_2_id", null: false
    t.boolean "user_1_layed_out", default: false, null: false
    t.boolean "user_2_layed_out", default: false, null: false
    t.boolean "rated", null: false
    t.boolean "five_shot", null: false
    t.integer "time_limit", null: false
    t.integer "turn_id", null: false
    t.integer "winner_id"
    t.boolean "del_user_1", default: false, null: false
    t.boolean "del_user_2", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_1_id"], name: "index_games_on_user_1_id"
    t.index ["user_2_id"], name: "index_games_on_user_2_id"
  end

  create_table "invites", force: :cascade do |t|
    t.integer "user_1_id", null: false
    t.integer "user_2_id", null: false
    t.boolean "rated", default: true, null: false
    t.boolean "five_shot", default: false, null: false
    t.integer "time_limit", default: 60, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_1_id", "user_2_id"], name: "index_invites_on_user_1_id_and_user_2_id", unique: true
  end

  create_table "layouts", force: :cascade do |t|
    t.integer "game_id", null: false
    t.integer "user_id", null: false
    t.integer "ship_id", null: false
    t.integer "x", null: false
    t.integer "y", null: false
    t.boolean "vertical", null: false
    t.boolean "sunk", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["sunk"], name: "index_layouts_on_sunk"
    t.index ["user_id", "game_id", "x", "y"], name: "index_layouts_on_user_id_and_game_id_and_x_and_y", unique: true
  end

  create_table "moves", force: :cascade do |t|
    t.integer "game_id", null: false
    t.integer "user_id", null: false
    t.integer "layout_id"
    t.integer "x", null: false
    t.integer "y", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["game_id", "user_id", "x", "y"], name: "index_moves_on_game_id_and_user_id_and_x_and_y", unique: true
  end

  create_table "sessions", force: :cascade do |t|
    t.string "session_id", null: false
    t.text "data"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["session_id"], name: "index_sessions_on_session_id", unique: true
    t.index ["updated_at"], name: "index_sessions_on_updated_at"
  end

  create_table "ships", force: :cascade do |t|
    t.string "name", limit: 12
    t.integer "size"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "username", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer "sign_in_count", default: 0, null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.inet "current_sign_in_ip"
    t.inet "last_sign_in_ip"
    t.string "confirmation_token"
    t.datetime "confirmed_at"
    t.datetime "confirmation_sent_at"
    t.string "unconfirmed_email"
    t.integer "failed_attempts", default: 0, null: false
    t.string "unlock_token"
    t.datetime "locked_at"
    t.boolean "bot", default: false, null: false
    t.integer "strength", default: 0, null: false
    t.integer "wins", default: 0, null: false
    t.integer "losses", default: 0, null: false
    t.integer "activity", default: 0, null: false
    t.integer "rating", default: 1200, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["confirmation_token"], name: "index_users_on_confirmation_token", unique: true
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["rating"], name: "index_users_on_rating"
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["unlock_token"], name: "index_users_on_unlock_token", unique: true
    t.index ["username"], name: "index_users_on_username", unique: true
  end

end
