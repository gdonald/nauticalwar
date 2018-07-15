class CreateInvites < ActiveRecord::Migration[5.2]
  def change
    create_table :invites do |t|
      t.integer :user_id_1, null: false
      t.integer :user_id_2, null: false
      t.boolean :rated, null: false, default: true
      t.boolean :five_shot, null: false, default: false
      t.integer :time_limit, null: false, default: 60
      t.timestamps
    end
    add_index :invites, %i[user_id_1 user_id_2], unique: true
  end
end
