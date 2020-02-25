class PlayerGuestField < ActiveRecord::Migration[6.0]
  def change
    add_column :players, :guest, :boolean, default: false, null: false
  end
end
