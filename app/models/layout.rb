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
  scope :sunk_for_user, ->(user) { where(sunk: true, user: user) }
  
  def is_hit?(c, r)
    if vertical && c == x
      (y..(y + ship.size)).each do |i|
        return true if i == r
      end
    elsif !vertical && r == y
      (x..(x + ship.size)).each do |i|
        return true if i == c
      end
    end
    false
  end
  
  def self.set_location(args)
    vertical = [0, 1].sample.zero?
    if vertical
      c = (0..9).to_a.sample
      r = (0..9).to_a.sample - args[:ship].size
      r = 0 if r < 0
      r = 10 - args[:ship].size if r > 10 - args[:ship].size
      (r..(r + args[:ship].size)).each do |x|
        unless args[:game].is_hit?(args[:user], c, x).nil?
          return Layout.set_location(args)
        end
      end
    else
      c = (0..9).to_a.sample - args[:ship].size
      r = (0..9).to_a.sample
      c = 0 if c < 0
      c = 10 - args[:ship].size if c > 10 - args[:ship].size
      (c..(c + args[:ship].size)).each do |x|
        unless args[:game].is_hit?(args[:user], x, r).nil?
          return Layout.set_location(args)
        end
      end
    end
    layout = Layout.new(game: args[:game], user: args[:user], ship: args[:ship], vertical: vertical, x: c, y: r)
    layout.save!
  end

  def check_sunk
    update_attributes(sunk: true) if moves.count >= ship.size
  end
end
