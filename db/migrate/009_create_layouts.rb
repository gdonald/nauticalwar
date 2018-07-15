class CreateLayouts < ActiveRecord::Migration[5.2]
  def change
    create_table :layouts do |t|
      t.integer :game_id, null: false
      t.integer :user_id, null: false
      t.integer :ship_id, null: false
      t.integer :x, null: false
      t.integer :y, null: false
      t.boolean :vertical, null: false
      t.timestamps
    end
    add_index :layouts, %i[game_id user_id ship_id x y], unique: true
  end
end
