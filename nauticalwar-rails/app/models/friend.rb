# frozen_string_literal: true

class Friend < ApplicationRecord
  belongs_to :player1, class_name: 'Player'
  belongs_to :player2, class_name: 'Player'

  validates :player2, uniqueness: { scope: :player1_id }

  def self.ransackable_attributes(_auth_object = nil)
    %w[created_at id id_value player1_id player2_id updated_at]
  end
end
