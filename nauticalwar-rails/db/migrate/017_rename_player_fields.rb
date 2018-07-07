# frozen_string_literal: true

class RenamePlayerFields < ActiveRecord::Migration[7.0]
  def change
    rename_column :games, :player_1_id, :player1_id
    rename_column :games, :player_2_id, :player2_id
    rename_column :games, :del_player_1, :del_player1 # rubocop:disable Naming/VariableNumber
    rename_column :games, :del_player_2, :del_player2 # rubocop:disable Naming/VariableNumber
    rename_column :games, :player_1_layed_out, :player1_layed_out
    rename_column :games, :player_2_layed_out, :player2_layed_out
    rename_column :enemies, :player_1_id, :player1_id
    rename_column :enemies, :player_2_id, :player2_id
    rename_column :friends, :player_1_id, :player1_id
    rename_column :friends, :player_2_id, :player2_id
    rename_column :invites, :player_1_id, :player1_id
    rename_column :invites, :player_2_id, :player2_id
  end
end
