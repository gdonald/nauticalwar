# frozen_string_literal: true

class Move < ApplicationRecord
  belongs_to :game
  belongs_to :player
  belongs_to :layout, optional: true

  validates :x, inclusion: { in: (0..9).to_a }
  validates :y, inclusion: { in: (0..9).to_a }

  validates :game, uniqueness: { scope: %i[player x y] }

  validate :layout_hits_max

  scope :ordered, -> { order(id: :desc) }
  scope :for_layout, ->(layout) { where(layout:) }
  scope :for_player, ->(player) { where(player:) }
  scope :for_xy, ->(x, y) { where(x:, y:) }

  def to_s
    "Move(player: #{player} layout: #{layout} x: #{x} y: #{y})"
  end

  def layout_hits_max
    return unless layout && layout.moves.count == layout.ship.size

    errors.add(:layout, 'ship already sunk')
  end
end
