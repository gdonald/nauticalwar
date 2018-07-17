class CreateMoves < ActiveRecord::Migration[5.2]
  def change
    create_table :moves do |t|
      t.integer :game_id, null: false
      t.integer :user_id, null: false
      t.integer :x, null: false
      t.integer :y, null: false
      t.timestamps
    end
    add_index :moves, %i[game_id user_id x y], unique: true
  end
end
