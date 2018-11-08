# frozen_string_literal: true

class Layout < ApplicationRecord
  belongs_to :player
  belongs_to :game
  belongs_to :ship

  has_many :moves

  validates :player, presence: true
  validates :game, presence: true
  validates :x, inclusion: { in: (0..9).to_a }
  validates :ship, presence: true
  validates :y, inclusion: { in: (0..9).to_a }

  validates :player, uniqueness: { scope: %i[game x y],
                                   message: 'layout must be unique' }

  validates :vertical, inclusion: [true, false]
  validates :sunk, inclusion: [true, false]

  scope :ordered, -> { order(id: :asc) }
  scope :unsunk, -> { where(sunk: false) }
  scope :for_player, ->(player) { where(player: player) }
  scope :sunk_for_player, ->(player) { where(sunk: true, player: player) }
  scope :unsunk_for_player, ->(player) { where(sunk: false, player: player) }

  def self.set_location(game, player, ship, vertical)
    c, r = if vertical
             game.vertical_location(player, ship)
           else
             game.horizontal_location(player, ship)
           end
    args = { player: player, ship: ship, vertical: vertical, x: c, y: r }
    game.layouts.create!(args)
  end

  def to_s
    "Layout(player: #{player} ship: #{ship} x: #{x} y: #{y} vertical: #{vertical})" # rubocop:disable Metrics/LineLength
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
    update_attributes(sunk: true) if moves.count >= ship.size
  end
end
