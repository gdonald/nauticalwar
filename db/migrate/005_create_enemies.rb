class CreateEnemies < ActiveRecord::Migration[5.2]
  def change
    create_table :enemies do |t|
      t.integer :user_id_1, null: false
      t.integer :user_id_2, null: false
      t.timestamps
    end
    add_index :enemies, %i[user_id_1 user_id_2], unique: true
  end
end
