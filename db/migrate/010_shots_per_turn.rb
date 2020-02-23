class ShotsPerTurn < ActiveRecord::Migration[6.0]
  def up
    add_column :invites, :shots_per_turn, :integer
    add_column :games, :shots_per_turn, :integer

    Invite.all.each do |i|
      i.shots_per_turn = i.shots_per_turn ? 5 : 1
      i.save!
    end

    Game.all.each do |g|
      g.shots_per_turn = g.shots_per_turn ? 5 : 1
      g.save!
    end

    remove_column :invites, :five_shot
    remove_column :games, :five_shot
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end