# frozen_string_literal: true

class CreatePlayers < ActiveRecord::Migration[5.2]
  def change # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
    create_table :players do |t|
      ## Database authenticatable
      t.string :email,              null: false, default: ''
      t.string :name,               null: false, default: ''
      t.string :encrypted_password, null: false, default: ''

      ## Recoverable
      t.string   :reset_password_token
      t.datetime :reset_password_sent_at

      ## Rememberable
      t.datetime :remember_created_at

      ## Trackable
      t.integer  :sign_in_count, null: false, default: 0
      t.datetime :current_sign_in_at
      t.datetime :last_sign_in_at
      t.inet     :current_sign_in_ip
      t.inet     :last_sign_in_ip

      ## Confirmable
      t.string   :confirmation_token
      t.datetime :confirmed_at
      t.datetime :confirmation_sent_at
      t.string   :unconfirmed_email # Only if using reconfirmable

      ## Lockable
      # Only if lock strategy is :failed_attempts
      t.integer  :failed_attempts, null: false, default: 0
      t.string   :unlock_token # Only if unlock strategy is :email or :both
      t.datetime :locked_at

      # Bot
      t.boolean :bot,      null: false, default: false
      t.integer :strength, null: false, default: 0

      # Ratings
      t.integer :wins,     null: false, default: 0
      t.integer :losses,   null: false, default: 0
      t.integer :activity, null: false, default: 0
      t.integer :rating,   null: false, default: 1200

      t.timestamps null: false
    end

    add_index :players, :email,                unique: true
    add_index :players, :name,                 unique: true
    add_index :players, :reset_password_token, unique: true
    add_index :players, :confirmation_token,   unique: true
    add_index :players, :unlock_token,         unique: true
    add_index :players, :rating
  end
end
