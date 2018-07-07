# frozen_string_literal: true

class Layout < ApplicationRecord
  belongs_to :player
  belongs_to :game
  belongs_to :ship

  has_many :moves, dependent: :destroy

  validates :x, inclusion: { in: (0..9).to_a }
  validates :y, inclusion: { in: (0..9).to_a }

  validates :player, uniqueness: { scope: %i[game x y],
                                   message: 'layout must be unique' }

  validates :vertical, inclusion: [true, false]
  validates :sunk, inclusion: [true, false]

  scope :ordered, -> { order(id: :asc) }
  scope :unsunk, -> { where(sunk: false) }
  scope :for_player, ->(player) { where(player:) }
  scope :sunk_for_player, ->(player) { where(sunk: true, player:) }
  scope :unsunk_for_player, ->(player) { where(sunk: false, player:) }

  def self.set_location(game, player, ship, vertical)
    c, r = if vertical
             game.vertical_location(player, ship)
           else
             game.horizontal_location(player, ship)
           end
    args = { player:, ship:, vertical:, x: c, y: r }
    game.layouts.create!(args)
  end

  def to_s
    "Layout(player: #{player} ship: #{ship} x: #{x} y: #{y} vertical: #{vertical})"
  end

  def horizontal
    !vertical
  end

  def vertical_hit?(col, row)
    if vertical && col == x
      (y...(y + ship.size)).each do |r|
        return true if r == row
      end
    end
    false
  end

  def horizontal_hit?(col, row)
    if horizontal && row == y
      (x...(x + ship.size)).each do |c|
        return true if c == col
      end
    end
    false
  end

  def hit?(col, row)
    vertical_hit?(col, row) || horizontal_hit?(col, row)
  end

  def sunk?
    update(sunk: true) if moves.count >= ship.size
  end
end
