# frozen_string_literal: true

class CreatePlayers < ActiveRecord::Migration[6.0]
  def change # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
    create_table :players do |t|
      t.string :email,              null: false, default: ''
      t.string :name,               null: false, default: ''
      t.string :p_salt, limit: 80
      t.string :p_hash, limit: 80

      # Bot
      t.boolean :bot,      null: false, default: false
      t.integer :strength, null: false, default: 0

      # Ratings
      t.integer :wins,     null: false, default: 0
      t.integer :losses,   null: false, default: 0
      t.integer :activity, null: false, default: 0
      t.integer :rating,   null: false, default: 1200

      # Admin
      t.boolean :admin,    null: false, default: false

      t.string :password_token
      t.timestamp :password_token_expire

      t.string :confirmation_token
      t.timestamp :confirmed_at
      t.timestamp :last_sign_in_at
      t.timestamps null: false
    end

    add_index :players, :email,                unique: true
    add_index :players, :name,                 unique: true
    add_index :players, :rating
  end
end
