# frozen_string_literal: true

class Move < ApplicationRecord
  belongs_to :game
  belongs_to :user
  belongs_to :layout, optional: true

  validates :x, inclusion: { in: (0..9).to_a }
  validates :y, inclusion: { in: (0..9).to_a }

  validates :game, uniqueness: { scope: %i[user x y] }

  validate :layout_hits_max

  scope :ordered, -> { order(id: :desc) }
  scope :for_layout, ->(layout) { where(layout: layout) }
  scope :for_user, ->(user) { where(user: user) }
  scope :for_xy, ->(x, y) { where(x: x, y: y) }

  def to_s
    "Move(user: #{user} layout: #{layout} x: #{x} y: #{y})"
  end

  def layout_hits_max
    if layout && layout.moves.count == layout.ship.size
      errors.add(:layout, 'ship already sunk')
    end
  end
end
