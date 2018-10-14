# frozen_string_literal: true

class CreateMoves < ActiveRecord::Migration[5.2]
  def change
    create_table :moves do |t|
      t.integer :game_id, null: false
      t.integer :player_id, null: false
      t.integer :layout_id
      t.integer :x, null: false
      t.integer :y, null: false
      t.timestamps
    end
    add_index :moves, %i[game_id player_id x y], unique: true
  end
end
