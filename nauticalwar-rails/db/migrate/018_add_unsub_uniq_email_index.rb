# frozen_string_literal: true

class AddUnsubUniqEmailIndex < ActiveRecord::Migration[7.0]
  def change
    add_index :unsubs, :email, unique: true
  end
end
