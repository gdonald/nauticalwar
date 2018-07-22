class CreateEnemies < ActiveRecord::Migration[5.2]
  def change
    create_table :enemies do |t|
      t.integer :user_1_id, null: false
      t.integer :user_2_id, null: false
      t.timestamps
    end
    add_index :enemies, %i[user_1_id user_2_id], unique: true
  end
end
