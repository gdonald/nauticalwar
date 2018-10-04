# frozen_string_literal: true

class CreateInvites < ActiveRecord::Migration[5.2]
  def change
    create_table :invites do |t|
      t.integer :user_1_id, null: false
      t.integer :user_2_id, null: false
      t.boolean :rated, null: false, default: true
      t.boolean :five_shot, null: false, default: false
      t.integer :time_limit, null: false, default: 60
      t.timestamps
    end
    add_index :invites, %i[user_1_id user_2_id], unique: true
  end
end
