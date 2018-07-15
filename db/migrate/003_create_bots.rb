class CreateBots < ActiveRecord::Migration[5.2]
  def change
    create_table :bots do |t|
      t.integer :user_id, null: false, unique: true
      t.timestamps
    end
  end
end
