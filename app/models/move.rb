class Move < ApplicationRecord

  belongs_to :game
  belongs_to :user

  validates :game, presence: true
  validates :user, presence: true
  validates :x, presence: true, inclusion: { in: (0..9).to_a }
  validates :y, presence: true, inclusion: { in: (0..9).to_a }

  validates :game, uniqueness: { scope: %i[user x y] }

end
