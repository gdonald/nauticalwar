class AddPlayerOptions < ActiveRecord::Migration[6.0]
  def change
    add_column :players, :hints, :boolean, default: true, null: false
    add_column :players, :water, :integer, default: 0, null: false
    add_column :players, :grid, :integer, default: 1, null: false
  end
end
