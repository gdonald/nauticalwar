# frozen_string_literal: true

class CreateLayouts < ActiveRecord::Migration[6.0]
  def change
    create_table :layouts do |t|
      t.integer :game_id, null: false
      t.integer :player_id, null: false
      t.integer :ship_id, null: false
      t.integer :x, null: false
      t.integer :y, null: false
      t.boolean :vertical, null: false, default: false
      t.boolean :sunk, null: false, default: false
      t.timestamps
    end
    add_index :layouts, %i[player_id game_id x y], unique: true
    add_index :layouts, :sunk
  end
end
