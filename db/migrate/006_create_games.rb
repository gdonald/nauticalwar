class CreateGames < ActiveRecord::Migration[5.2]
  def change
    create_table :games do |t|
      t.integer :user_id_1, null: false
      t.integer :user_id_2, null: false
      t.boolean :rated, null: false
      t.boolean :five_shot, null: false
      t.integer :time_limit, null: false
      t.integer :turn
      t.integer :winner
      t.boolean :del_user_1, null: false, default: false
      t.boolean :del_user_2, null: false, default: false
      t.timestamps
    end
    add_index :games, %i[user_id_1 user_id_2], unique: true
  end
end
