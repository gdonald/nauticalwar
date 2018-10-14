# frozen_string_literal: true

class CreateFriends < ActiveRecord::Migration[5.2]
  def change
    create_table :friends do |t|
      t.integer :player_1_id, null: false
      t.integer :player_2_id, null: false
      t.timestamps
    end
    add_index :friends, %i[player_1_id player_2_id], unique: true
  end
end
