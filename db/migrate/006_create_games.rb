# frozen_string_literal: true

class CreateGames < ActiveRecord::Migration[6.0]
  def change # rubocop:disable Metrics/MethodLength
    create_table :games do |t|
      t.integer :player_1_id, null: false
      t.integer :player_2_id, null: false
      t.boolean :player_1_layed_out, null: false, default: false
      t.boolean :player_2_layed_out, null: false, default: false
      t.boolean :rated, null: false
      t.boolean :five_shot, null: false
      t.integer :time_limit, null: false
      t.integer :turn_id, null: false
      t.integer :winner_id
      t.boolean :del_player_1, null: false, default: false
      t.boolean :del_player_2, null: false, default: false
      t.timestamps
    end
    add_index :games, :player_1_id
    add_index :games, :player_2_id
  end
end
