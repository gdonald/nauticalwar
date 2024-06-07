# frozen_string_literal: true

class AddUnsubHash < ActiveRecord::Migration[6.0]
  def change
    add_column :players, :unsub_hash, :string
  end
end
