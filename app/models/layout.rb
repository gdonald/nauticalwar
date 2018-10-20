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

  def self.set_location(args)
    game = args[:game]
    ship = args[:ship]
    player = args[:player]
    vertical = [0, 1].sample.zero?
    if vertical
      c = (0..9).to_a.sample
      r = (0..(10 - ship.size)).to_a.sample
      (r...(r + ship.size)).each do |y|
        return Layout.set_location(args) unless game.hit?(player, c, y).nil?
      end
    else
      c = (0..(10 - ship.size)).to_a.sample
      r = (0..9).to_a.sample
      (c...(c + ship.size)).each do |x|
        return Layout.set_location(args) unless game.hit?(player, x, r).nil?
      end
    end
    Layout.create!(game: game, player: player, ship: ship, vertical: vertical, x: c, y: r)
  end

  def check_sunk
    update_attributes(sunk: true) if moves.count >= ship.size
  end
end
