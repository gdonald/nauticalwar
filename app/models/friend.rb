# frozen_string_literal: true

class Friend < ApplicationRecord
  belongs_to :player1, class_name: 'Player'
  belongs_to :player2, class_name: 'Player'

  validates :player2, uniqueness: { scope: :player1_id }
end
