# frozen_string_literal: true

class CreateInvites < ActiveRecord::Migration[5.2]
  def change
    create_table :invites do |t|
      t.integer :player_1_id, null: false
      t.integer :player_2_id, null: false
      t.boolean :rated, null: false, default: true
      t.boolean :five_shot, null: false, default: false
      t.integer :time_limit, null: false, default: 60
      t.timestamps
    end
    add_index :invites, %i[player_1_id player_2_id], unique: true
  end
end
