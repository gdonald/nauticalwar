class CreateShips < ActiveRecord::Migration[5.2]
  def change
    create_table :ships do |t|
      t.string :name, limit: 12, unique: true
      t.integer :size
      t.timestamps
    end
  end
end
