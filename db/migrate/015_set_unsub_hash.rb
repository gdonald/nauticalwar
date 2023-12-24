# frozen_string_literal: true

class SetUnsubHash < ActiveRecord::Migration[6.0]
  def up
    Player.find_each do |player|
      player.update(unsub_hash: Player.generate_unique_secure_token)
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
