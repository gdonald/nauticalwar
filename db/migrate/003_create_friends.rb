# frozen_string_literal: true

class CreateFriends < ActiveRecord::Migration[5.2]
  def change
    create_table :friends do |t|
      t.integer :user_1_id, null: false
      t.integer :user_2_id, null: false
      t.timestamps
    end
    add_index :friends, %i[user_1_id user_2_id], unique: true
  end
end
