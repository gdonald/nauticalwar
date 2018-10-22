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

  validates :player, uniqueness: { scope: %i[game x y], message: 'layout must be unique' }

  validates :vertical, inclusion: [true, false]
  validates :sunk, inclusion: [true, false]

  scope :ordered, -> { order(id: :asc) }
  scope :unsunk, -> { where(sunk: false) }
  scope :for_player, ->(player) { where(player: player) }
  scope :sunk_for_player, ->(player) { where(sunk: true, player: player) }
  scope :unsunk_for_player, ->(player) { where(sunk: false, player: player) }

  def self.sample_col_row(col_max, row_max)
    [(0..col_max).to_a.sample, (0..row_max).to_a.sample]
  end

  def self.vertical_location(game, player, ship)
    c, r = Layout.sample_col_row(9, 10 - ship.size)
    (r...(r + ship.size)).each do |y|
      if game.hit?(player, c, y).present?
        return Layout.vertical_location(game, player, ship)
      end
    end
    [c, r]
  end

  def self.horizontal_location(game, player, ship)
    c, r = Layout.sample_col_row(10 - ship.size, 9)
    (c...(c + ship.size)).each do |x|
      if game.hit?(player, x, r).present?
        return Layout.horizontal_location(game, player, ship)
      end
    end
    [c, r]
  end

  def self.set_location(game, player, ship, vertical)
    c, r = if vertical
             Layout.vertical_location(game, player, ship)
           else
             Layout.horizontal_location(game, player, ship)
           end
    args = { player: player, ship: ship, vertical: vertical, x: c, y: r }
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
    update_attributes(sunk: true) if moves.count >= ship.size
  end
end
