# frozen_string_literal: true

class Invite < ApplicationRecord
  attr_accessor :game_id

  belongs_to :player_1, class_name: 'Player', foreign_key: 'player_1_id'
  belongs_to :player_2, class_name: 'Player', foreign_key: 'player_2_id'

  validates :player_2, uniqueness: {scope: :player_1_id,
                                    message: 'Invite already exists'}

  validates :rated, inclusion: [true, false]
  validates :shots_per_turn, inclusion: 1..5
  validates :time_limit, inclusion: [300, 900, 3600, 28_800, 86_400]

  validate :cannot_invite_self

  scope :ordered, -> { order(created_at: :asc) }

  def self.shot_opts
    (1..5).to_a.reverse
  end

  def self.time_limits
    { '86400': '1 day',
      '28800': '8 hours',
      '3600': '1 hour',
      '900': '15 minutes',
      '300': '5 minutes' }
  end

  def cannot_invite_self
    errors.add(:player_2, 'Cannot invite self') if player_1 == player_2
  end

  def create_game
    player_2.new_activity!
    attrs = attributes.except('id', 'created_at', 'updated_at')
                .merge('turn' => player_1)
    Game.create!(attrs)
  end
end
