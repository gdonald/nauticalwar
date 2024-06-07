# frozen_string_literal: true

class CreateEnemies < ActiveRecord::Migration[6.0]
  def change
    create_table :enemies do |t|
      t.integer :player_1_id, null: false
      t.integer :player_2_id, null: false
      t.timestamps
    end
    add_index :enemies, %i[player_1_id player_2_id], unique: true
  end
end
