class CreateGames < ActiveRecord::Migration[5.2]
  def change
    create_table :games do |t|
      t.integer :user_1_id, null: false
      t.integer :user_2_id, null: false
      t.boolean :user_1_layed_out, null: false, default: false
      t.boolean :user_2_layed_out, null: false, default: false
      t.boolean :rated, null: false
      t.boolean :five_shot, null: false
      t.integer :time_limit, null: false
      t.integer :turn_id, null: false
      t.integer :winner_id
      t.boolean :del_user_1, null: false, default: false
      t.boolean :del_user_2, null: false, default: false
      t.timestamps
    end
    add_index :games, %i[user_1_id user_2_id], unique: true
  end
end
