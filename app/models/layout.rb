class Layout < ApplicationRecord

  belongs_to :user
  belongs_to :game
  belongs_to :ship

  validates :user, presence: true
  validates :game, presence: true
  validates :ship, presence: true
  validates :x, presence: true, inclusion: { in: (0..9).to_a }
  validates :y, presence: true, inclusion: { in: (0..9).to_a }

  validates :user, uniqueness: { scope: %i[game ship x y] }

  validates :vertical, presence: true
  
end
