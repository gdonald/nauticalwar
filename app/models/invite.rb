# frozen_string_literal: true

class Invite < ApplicationRecord
  attr_accessor :game_id

  belongs_to :player_1, class_name: 'Player', foreign_key: 'player_1_id'
  belongs_to :player_2, class_name: 'Player', foreign_key: 'player_2_id'

  validates :player_1, presence: true
  validates :player_2, presence: true
  validates :player_2, uniqueness: { scope: :player_1_id, message: 'Invite already exists' }

  validates :rated, inclusion: [true, false]
  validates :five_shot, inclusion: [true, false]
  validates :time_limit, presence: true

  validate :cannot_invite_self

  scope :ordered, -> { order(created_at: :asc) }

  def cannot_invite_self
    errors.add(:player_2, 'Cannot invite self') if player_1 == player_2
  end

  def create_game
    player_2.update_attributes(activity: player_2.activity + 1)
    attrs = attributes.except('id', 'created_at', 'updated_at').merge('turn' => player_1)
    Game.create!(attrs)
  end
end
