# frozen_string_literal: true

class CreateUnsubs < ActiveRecord::Migration[6.0]
  def change
    create_table :unsubs do |t|
      t.string :email, unique: true, null: false
      t.timestamps
    end
  end
end
