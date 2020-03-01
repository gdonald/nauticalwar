# frozen_string_literal: true

class Enemy < ApplicationRecord
  belongs_to :player_1, class_name: 'Player', foreign_key: 'player_1_id'
  belongs_to :player_2, class_name: 'Player', foreign_key: 'player_2_id'

  # validates :player_1, presence: true
  # validates :player_2, presence: true
  validates :player_2, uniqueness: { scope: :player_1_id }
end
