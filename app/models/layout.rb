class Layout < ApplicationRecord

  belongs_to :user
  belongs_to :game
  belongs_to :ship

  has_many :moves
  
  validates :user, presence: true
  validates :game, presence: true
  validates :ship, presence: true
  validates :x, inclusion: { in: (0..9).to_a }
  validates :y, inclusion: { in: (0..9).to_a }

  validates :user, uniqueness: { scope: %i[game x y], message: 'layout must be unique' }

  validates :vertical, inclusion: [true, false]
  validates :sunk, inclusion: [true, false]

  scope :ordered, -> { order(id: :asc) }
  scope :unsunk, -> { where(sunk: false) }
  scope :for_user, ->(user) { where(user: user) }
  scope :sunk_for_user, ->(user) { where(sunk: true, user: user) }
  scope :unsunk_for_user, ->(user) { where(sunk: false, user: user) }

  def to_s
    "Layout(user: #{user} ship: #{ship} x: #{x} y: #{y} vertical: #{vertical})"
  end
  
  def is_hit?(c, r)
    if vertical && c == x
      (y...(y + ship.size)).each do |i|
        return true if i == r
      end
    elsif !vertical && r == y
      (x...(x + ship.size)).each do |i|
        return true if i == c
      end
    end
    false
  end
  
  def self.set_location(args)
    game, ship, user = args[:game], args[:ship], args[:user]
    vertical = [0, 1].sample.zero?
    if vertical
      c = (0..9).to_a.sample
      r = (0..(10 - ship.size)).to_a.sample
      (r...(r + ship.size)).each do |y|
        return Layout.set_location(args) unless game.is_hit?(user, c, y).nil?
      end
    else
      c = (0..(10 - ship.size)).to_a.sample
      r = (0..9).to_a.sample
      (c...(c + ship.size)).each do |x|
        return Layout.set_location(args) unless game.is_hit?(user, x, r).nil?
      end
    end
    Layout.create!(game: game, user: user, ship: ship, vertical: vertical, x: c, y: r)
  end

  def check_sunk
    update_attributes(sunk: true) if moves.count >= ship.size
  end

end
